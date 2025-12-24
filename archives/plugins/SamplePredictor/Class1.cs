using System;
using System.Collections.Generic;
using System.Threading;
using System.Management.Automation;
using System.Management.Automation.Subsystem;
using System.Management.Automation.Subsystem.Prediction;

namespace PowerShell.Sample
{
    public class SamplePredictor : ICommandPredictor
    {
        private readonly Guid _guid;

        internal SamplePredictor(string guid)
        {
            _guid = new Guid(guid);
        }

        public Guid Id => _guid;
        public string Name => "TerraformPredictor";
        public string Description => "Predicts common terraform commands and flags";

        // ---- static command model ------------------------------------------

        private static readonly string[] Commands =
        {
            "init",
            "plan",
            "apply",
            "destroy",
            "validate",
            "fmt",
            "providers",
            "state",
            "workspace",
            "refresh"
        };

        private static readonly Dictionary<string, string[]> Flags =
            new(StringComparer.OrdinalIgnoreCase)
            {
                ["init"] = new[]
                {
                    "-upgrade",
                    "-reconfigure"
                },
                ["plan"] = new[]
                {
                    "-out=tfplan",
                    "-destroy",
                    "-refresh=true",
                    "-var-file=vars.tfvars"
                },
                ["apply"] = new[]
                {
                    "-auto-approve",
                    "-refresh=true"
                },
                ["destroy"] = new[]
                {
                    "-auto-approve"
                },
                ["fmt"] = new[]
                {
                    "-recursive",
                    "-check"
                }
            };

        // ---- prediction entry point ----------------------------------------

        public SuggestionPackage GetSuggestion(
            PredictionClient client,
            PredictionContext context,
            CancellationToken cancellationToken)
        {
            var input = context.InputAst.Extent.Text;
            if (string.IsNullOrWhiteSpace(input))
                return default;

            var trimmed = input.TrimStart();

            // Only trigger for terraform
            if (!trimmed.StartsWith("ter", StringComparison.OrdinalIgnoreCase))
                return default;

            // Text after `terraform`
            var after = trimmed.Length > 9
                ? trimmed.Substring(9).TrimStart()
                : string.Empty;

            var suggestions = new List<PredictiveSuggestion>();

            // ---- terraform <partial> ---------------------------------------

            if (after.Length == 0 || !after.Contains(' '))
            {
                foreach (var cmd in Commands)
                {
                    if (cmd.StartsWith(after, StringComparison.OrdinalIgnoreCase))
                    {
                        suggestions.Add(
                            Suggest(
                                $"terraform {cmd}",
                                $"terraform {cmd} command"
                            )
                        );
                    }
                }

                return suggestions.Count > 0
                    ? new SuggestionPackage(suggestions)
                    : default;
            }

            // ---- terraform <cmd> <partial-flag> -----------------------------

            var parts = after.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var subcommand = parts[0];

            if (!Flags.TryGetValue(subcommand, out var flags))
                return default;

            var flagPrefix = parts.Length > 1
                ? parts[^1]
                : string.Empty;

            foreach (var flag in flags)
            {
                if (flag.StartsWith(flagPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    suggestions.Add(
                        Suggest(
                            $"terraform {subcommand} {flag}",
                            $"terraform {subcommand} option"
                        )
                    );
                }
            }

            return suggestions.Count > 0
                ? new SuggestionPackage(suggestions)
                : default;
        }

        // ---- feedback hooks (required, intentionally no-ops) ---------------

        public bool CanAcceptFeedback(PredictionClient client, PredictorFeedbackKind feedback) => false;
        public void OnSuggestionDisplayed(PredictionClient client, uint session, int countOrIndex) { }
        public void OnSuggestionAccepted(PredictionClient client, uint session, string acceptedSuggestion) { }
        public void OnCommandLineAccepted(PredictionClient client, IReadOnlyList<string> history) { }
        public void OnCommandLineExecuted(PredictionClient client, string commandLine, bool success) { }

        // ---- helpers --------------------------------------------------------

        private static PredictiveSuggestion Suggest(string text, string tooltip) =>
            new(text, tooltip);
    }

    // ---- module lifecycle --------------------------------------------------

    public class Init : IModuleAssemblyInitializer, IModuleAssemblyCleanup
    {
        private const string Identifier = "843b51d0-55c8-4c1a-8116-f0728d419306";

        public void OnImport()
        {
            var predictor = new SamplePredictor(Identifier);
            SubsystemManager.RegisterSubsystem(
                SubsystemKind.CommandPredictor,
                predictor
            );
        }

        public void OnRemove(PSModuleInfo psModuleInfo)
        {
            SubsystemManager.UnregisterSubsystem(
                SubsystemKind.CommandPredictor,
                new Guid(Identifier)
            );
        }
    }
}
