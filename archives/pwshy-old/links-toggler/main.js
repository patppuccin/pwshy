const { Plugin, PluginSettingTab, Setting, Notice } = require("obsidian");

const DEFAULT_SETTINGS = {
  excludedExtensions: "png,jpg,jpeg,gif,svg,pdf",
  safeMode: true, // vault-wide ops are dry-run by default
  mdLinkStyle: "absolute", // "absolute" | "relative"
  ignoredFolders: [], // array of folder paths relative to vault root
};

module.exports = class LinkConverterPlugin extends Plugin {
  async onload() {
    await this.loadSettings();

    // Status bar indicator
    this.statusBarItem = this.addStatusBarItem();
    this.setStatusBarText("Idle");

    // Command: Convert current file wikilinks to markdown
    this.addCommand({
      id: "wiki-to-md-current",
      name: "Convert wikilinks to markdown links (current file)",
      editorCallback: (editor, view) => {
        this.convertLinksInEditor(editor, view, "wiki-to-md");
      },
    });

    // Command: Convert current file markdown to wikilinks
    this.addCommand({
      id: "md-to-wiki-current",
      name: "Convert markdown links to wikilinks (current file)",
      editorCallback: (editor, view) => {
        this.convertLinksInEditor(editor, view, "md-to-wiki");
      },
    });

    // Command: Convert entire vault wikilinks to markdown
    this.addCommand({
      id: "wiki-to-md-vault",
      name: "Convert wikilinks to markdown links (entire vault)",
      callback: () => {
        this.convertLinksInVault("wiki-to-md");
      },
    });

    // Command: Convert entire vault markdown to wikilinks
    this.addCommand({
      id: "md-to-wiki-vault",
      name: "Convert markdown links to wikilinks (entire vault)",
      callback: () => {
        this.convertLinksInVault("md-to-wiki");
      },
    });

    this.addCommand({
      id: "vault-safe-mode-toggle",
      name: "Toggle safe mode for vault-wide conversions",
      callback: async () => {
        this.settings.safeMode = !this.settings.safeMode;
        await this.saveSettings();

        const state = this.settings.safeMode
          ? "ON (Dry Run)"
          : "OFF (Writes Enabled)";

        new Notice(`Safe Mode is now ${state}`);
        this.setStatusBarText(`Safe Mode: ${state}`);

        // Reset status bar after a moment
        setTimeout(() => this.setStatusBarText("Idle"), 3000);
      },
    });

    this.addSettingTab(new LinkConverterSettingTab(this.app, this));
  }

  onunload() {
    if (this.statusBarItem) {
      this.statusBarItem.remove();
    }
  }

  async loadSettings() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
    // Normalize types
    if (!Array.isArray(this.settings.ignoredFolders)) {
      this.settings.ignoredFolders = [];
    }
  }

  async saveSettings() {
    await this.saveData(this.settings);
  }

  setStatusBarText(text) {
    if (!this.statusBarItem) return;
    this.statusBarItem.setText(`Links Toggler: ${text}`);
  }

  // Helpers for settings

  getExcludedExtensions() {
    return this.settings.excludedExtensions
      .split(",")
      .map((ext) => ext.trim().toLowerCase())
      .filter((ext) => ext.length > 0);
  }

  getIgnoredFoldersNormalized() {
    return this.settings.ignoredFolders.map((p) => this.normalizeFolderPath(p));
  }

  normalizeFolderPath(path) {
    if (!path) return "";
    let p = path.trim();
    if (p.startsWith("/")) p = p.substring(1);
    if (p.endsWith("/")) p = p.slice(0, -1);
    return p;
  }

  shouldIgnoreFile(file, ignoredFolders) {
    if (!ignoredFolders || ignoredFolders.length === 0) return false;
    const filePath = file.path;
    return ignoredFolders.some((folder) => {
      if (!folder) return false;
      return filePath === folder || filePath.startsWith(folder + "/");
    });
  }

  isExcludedByExtension(pathOrName, excludedExts) {
    if (!excludedExts || excludedExts.length === 0) return false;
    const lower = pathOrName.toLowerCase();
    return excludedExts.some((ext) => lower.endsWith("." + ext));
  }

  // Compute a relative path from "fromPath" (file) to "toPath" (file)
  getRelativePath(fromPath, toPath) {
    const fromParts = fromPath.split("/").slice(0, -1); // directory of source file
    const toParts = toPath.split("/");

    let commonIndex = 0;
    while (
      commonIndex < fromParts.length &&
      commonIndex < toParts.length &&
      fromParts[commonIndex] === toParts[commonIndex]
    ) {
      commonIndex++;
    }

    const upSegments = fromParts.slice(commonIndex).map(() => "..");
    const downSegments = toParts.slice(commonIndex);
    const segments = [...upSegments, ...downSegments];

    if (segments.length === 0) {
      // Same folder/file, just return basename
      return toParts[toParts.length - 1];
    }

    return segments.join("/");
  }

  // Resolve a wikilink base (without alias, without heading) to a vault-relative path
  resolveWikilink(linkBase, currentFile) {
    const cleanLink = linkBase.trim();

    const hasExtension = /\.\w+$/.test(cleanLink);
    let file = null;

    const sourcePath = currentFile?.path || "";

    if (hasExtension) {
      file = this.app.metadataCache.getFirstLinkpathDest(cleanLink, sourcePath);
    } else {
      file = this.app.metadataCache.getFirstLinkpathDest(
        cleanLink + ".md",
        sourcePath,
      );
      if (!file) {
        file = this.app.metadataCache.getFirstLinkpathDest(
          cleanLink,
          sourcePath,
        );
      }
    }

    if (file) {
      // Return vault-relative path like "Folder/File.md"
      return file.path;
    }

    // If file not found, return the original link text
    return cleanLink;
  }

  // Resolve markdown link path (no hash) to a wikilink target
  resolveMdLink(linkPath, currentFile) {
    // External links: leave as-is
    if (/^[a-zA-Z]+:\/\//.test(linkPath)) {
      return linkPath;
    }

    let cleanPath = linkPath.trim();

    // Remove leading slash if present (absolute vault path)
    if (cleanPath.startsWith("/")) {
      cleanPath = cleanPath.substring(1);
    } else if (currentFile) {
      // Resolve relative to current file location
      cleanPath = this.resolveRelativePath(cleanPath, currentFile);
    }

    const file = this.app.vault.getAbstractFileByPath(cleanPath);

    if (file && file.extension) {
      if (file.extension.toLowerCase() === "md") {
        return file.basename;
      }
      return file.name;
    }

    // If file not found, return original path
    return linkPath;
  }

  resolveRelativePath(linkPath, currentFile) {
    if (!currentFile) return linkPath;

    const baseDirs = currentFile.path.split("/").slice(0, -1);
    const segments = linkPath.split("/");

    const stack = [...baseDirs];

    for (const segment of segments) {
      if (segment === "" || segment === ".") continue;
      if (segment === "..") {
        if (stack.length > 0) stack.pop();
      } else {
        stack.push(segment);
      }
    }

    return stack.join("/");
  }

  getMarkdownPathForResolved(resolvedPath, currentFile) {
    // resolvedPath is either a vault-relative path ("Folder/File.md") or some arbitrary text
    if (/^[a-zA-Z]+:\/\//.test(resolvedPath)) {
      return resolvedPath;
    }

    if (this.settings.mdLinkStyle === "relative" && currentFile) {
      return this.getRelativePath(currentFile.path, resolvedPath);
    }

    // Absolute style: prefix with "/"
    if (resolvedPath.startsWith("/")) return resolvedPath;
    return "/" + resolvedPath;
  }

  convertLinksInEditor(editor, view, mode) {
    const content = editor.getValue();
    const currentFile = view.file;
    const converted = this.convertLinks(content, mode, currentFile);

    if (content !== converted) {
      // Use CodeMirror transaction if possible to keep undo more granular
      if (editor.cm && editor.cm.dispatch) {
        editor.cm.dispatch({
          changes: {
            from: 0,
            to: content.length,
            insert: converted,
          },
        });
      } else {
        editor.setValue(converted);
      }

      new Notice("Converted links in current file");
      this.setStatusBarText("Converted current file");
      setTimeout(() => this.setStatusBarText("Idle"), 2000);
    } else {
      new Notice("No links to convert in current file");
      this.setStatusBarText("No changes");
      setTimeout(() => this.setStatusBarText("Idle"), 2000);
    }
  }

  async convertLinksInVault(mode) {
    const files = this.app.vault.getMarkdownFiles();
    const ignoredFolders = this.getIgnoredFoldersNormalized();
    const excludedExts = this.getExcludedExtensions();

    let modifiedFiles = 0;
    const modifyTasks = [];

    const isDryRun = !!this.settings.safeMode;

    this.setStatusBarText(
      isDryRun ? "Scanning (safe mode)" : "Converting (vault)",
    );

    for (const file of files) {
      if (this.shouldIgnoreFile(file, ignoredFolders)) {
        continue;
      }

      const content = await this.app.vault.read(file);
      const newContent = this.convertLinks(content, mode, file, excludedExts);

      if (content !== newContent) {
        modifiedFiles++;

        if (!isDryRun) {
          modifyTasks.push(this.app.vault.modify(file, newContent));
        }
      }
    }

    if (!isDryRun && modifyTasks.length > 0) {
      await Promise.all(modifyTasks);
    }

    if (isDryRun) {
      new Notice(
        `Safe mode: ${modifiedFiles} file(s) would be modified. Disable safe mode to apply changes.`,
      );
      this.setStatusBarText(`Safe mode: ${modifiedFiles} file(s) affected`);
    } else {
      new Notice(`Converted links in ${modifiedFiles} file(s)`);
      this.setStatusBarText(`Converted ${modifiedFiles} file(s)`);
    }

    setTimeout(() => this.setStatusBarText("Idle"), 3000);
  }

  convertLinks(content, mode, currentFile, precomputedExcludedExts) {
    const excludedExts =
      precomputedExcludedExts || this.getExcludedExtensions();

    if (mode === "wiki-to-md") {
      // [[link]], [[link|alias]], [[link#heading]], [[link#^block|alias]]
      return content.replace(/\[\[([^[\]]+?)\]\]/g, (match, inner) => {
        // inner might be: "Note", "Note|Alias", "Note#Heading", "Note#^block|Alias"
        const [targetAndSubRaw, aliasRaw] = inner.split("|");
        const targetAndSub = (targetAndSubRaw || "").trim();
        const alias = (aliasRaw || targetAndSub).trim();

        if (!targetAndSub) return match;

        const [baseRaw, subpathRaw] = targetAndSub.split("#");
        const base = baseRaw.trim();
        const subpath = subpathRaw ? subpathRaw.trim() : null;

        const resolvedPath = this.resolveWikilink(base, currentFile);
        const markdownPathBase = this.getMarkdownPathForResolved(
          resolvedPath,
          currentFile,
        );

        let fullPath = markdownPathBase;
        if (subpath) {
          // Preserve heading/block as hash
          fullPath = `${markdownPathBase}#${subpath}`;
        }

        if (this.isExcludedByExtension(fullPath, excludedExts)) {
          return match;
        }

        const encodedPath = encodeURI(fullPath);
        return `[${alias}](${encodedPath})`;
      });
    } else {
      // Markdown to wikilink
      // Match: [text](path) or [text](path "title"), ignoring images ![...]
      const mdLinkRegex = /(!)?\[([^\]]+?)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g;

      return content.replace(mdLinkRegex, (match, bang, text, linkTarget) => {
        if (bang) {
          // Image: leave untouched
          return match;
        }

        const decodedLink = decodeURI(linkTarget);

        // Split out any hash (#heading or #^block)
        const [pathRaw, subpathRaw] = decodedLink.split("#");
        const cleanPath = (pathRaw || "").trim();
        const subpath = subpathRaw ? subpathRaw.trim() : null;

        if (!cleanPath) {
          return match;
        }

        if (this.isExcludedByExtension(cleanPath, excludedExts)) {
          return match;
        }

        const resolvedLink = this.resolveMdLink(cleanPath, currentFile);
        const basename = resolvedLink.replace(/\.md$/i, "");

        let core = resolvedLink;
        if (subpath) {
          core = `${resolvedLink}#${subpath}`;
        }

        // Decide alias vs plain wikilink
        const isSameAsBase =
          text === basename || text === resolvedLink || text === core;

        if (isSameAsBase) {
          return `[[${core}]]`;
        }

        return `[[${core}|${text}]]`;
      });
    }
  }
};

class LinkConverterSettingTab extends PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    /** @type {LinkConverterPlugin} */
    this.plugin = plugin;
  }

  display() {
    const { containerEl } = this;
    containerEl.empty();

    containerEl.createEl("h1", { text: "Links Toggler Settings" });

    // Safe mode
    new Setting(containerEl)
      .setName("Safe mode for vault-wide conversions")
      .setDesc(
        "When enabled, vault-wide conversions only report how many files would change, without modifying anything.",
      )
      .addToggle((toggle) => {
        toggle
          .setValue(this.plugin.settings.safeMode)
          .onChange(async (value) => {
            this.plugin.settings.safeMode = value;
            await this.plugin.saveSettings();
          });
      });

    // Markdown link style
    new Setting(containerEl)
      .setName("Markdown link style")
      .setDesc(
        "Choose whether generated markdown links use absolute paths (/Folder/File.md) or paths relative to the current file.",
      )
      .addDropdown((dropdown) => {
        dropdown
          .addOption("absolute", "Absolute (/Folder/File.md)")
          .addOption("relative", "Relative (../Folder/File.md)")
          .setValue(this.plugin.settings.mdLinkStyle || "absolute")
          .onChange(async (value) => {
            this.plugin.settings.mdLinkStyle = value;
            await this.plugin.saveSettings();
          });
      });

    // Excluded file extensions
    new Setting(containerEl)
      .setName("Excluded target file extensions")
      .setDesc(
        "Comma-separated list of file extensions (without dot). Links pointing to these will not be converted (e.g., png,jpg,pdf).",
      )
      .addText((text) =>
        text
          .setPlaceholder("png,jpg,pdf")
          .setValue(this.plugin.settings.excludedExtensions)
          .onChange(async (value) => {
            this.plugin.settings.excludedExtensions = value;
            await this.plugin.saveSettings();
          }),
      );

    containerEl.createEl("h2", { text: "Ignored folders (vault-wide)" });

    const ignoredFolders = this.plugin.getIgnoredFoldersNormalized();

    if (ignoredFolders.length === 0) {
      const info = containerEl.createEl("div");
      info.setText(
        "No folders are ignored. All markdown files are eligible for vault-wide conversions.",
      );
      info.style.marginBottom = "8px";
    }

    // Existing ignored folders
    ignoredFolders.forEach((folder) => {
      const setting = new Setting(containerEl)
        .setName(folder)
        .setDesc("This folder is ignored during vault-wide conversions.")
        .addExtraButton((button) => {
          button
            .setIcon("trash")
            .setTooltip("Remove from ignored folders")
            .onClick(async () => {
              this.plugin.settings.ignoredFolders =
                this.plugin.settings.ignoredFolders.filter(
                  (f) => this.plugin.normalizeFolderPath(f) !== folder,
                );
              await this.plugin.saveSettings();
              this.display();
            });
        });

      setting.infoEl.style.opacity = "0.8";
    });

    // Add new ignored folder
    new Setting(containerEl)
      .setName("Add ignored folder")
      .setDesc(
        "Enter a folder path relative to the vault root (e.g., Templates, Archive/Old).",
      )
      .addText((text) => {
        text.setPlaceholder("Templates or Projects/Archive");
        this._ignoredFolderInput = text;
      })
      .addExtraButton((button) => {
        button
          .setIcon("plus")
          .setTooltip("Add folder to ignore list")
          .onClick(async () => {
            const value = this._ignoredFolderInput.getValue().trim();
            if (!value) return;

            const normalized = this.plugin.normalizeFolderPath(value);
            if (!normalized) return;

            if (
              !this.plugin.settings.ignoredFolders.some(
                (f) => this.plugin.normalizeFolderPath(f) === normalized,
              )
            ) {
              this.plugin.settings.ignoredFolders.push(normalized);
              await this.plugin.saveSettings();
              this.display();
            }

            this._ignoredFolderInput.setValue("");
          });
      });
  }
}
