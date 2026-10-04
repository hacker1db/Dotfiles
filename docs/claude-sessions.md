# Claude Code sessions

Run these in separate terminal tabs or tmux panes:

```sh
claude-subscription
claude-foundry
```

The commands are available through the existing dotfiles `bin` PATH entry. They choose the provider for that invocation and leave global settings, backend markers, subscription login, and the status line untouched. Plain `claude`, `cc`, and the legacy backend installer retain their existing behavior.

Subscription sessions use your existing Claude subscription login and the model in `claude/settings.base.json`. Foundry sessions use your `az login` credentials and the deployment defaults in `claude/settings.foundry.json`. Azure CLI and jq must be installed. Inherited API keys, bearer tokens, other provider flags, and Azure service principal credentials are cleared for the child process.

Select a resource or endpoint for a particular session:

```sh
az login
ANTHROPIC_FOUNDRY_RESOURCE=my-resource claude-foundry
ANTHROPIC_FOUNDRY_BASE_URL=https://my-resource.services.ai.azure.com/anthropic claude-foundry
```

When neither is supplied, discovery uses the active Azure subscription and requires exactly one AIServices resource. With multiple resources, select one explicitly. The resource must already have Claude deployments and your Azure identity must have permission to invoke them.

Override deployment names or forward ordinary Claude options:

```sh
ANTHROPIC_DEFAULT_OPUS_MODEL=my-opus-deployment claude-foundry
ANTHROPIC_DEFAULT_SONNET_MODEL=my-sonnet-deployment claude-foundry --model sonnet
claude-subscription --continue
```

Each launch uses a private temporary settings file, removed when Claude exits. Shared user/project settings still load, including your hooks, plugins, permissions, and status line. Local autoMode settings use the same file resolution as the legacy installer. The launchers reserve `--settings` for provider isolation; organization-managed settings retain their normal precedence. Use `/status` inside each session to confirm the provider. This workflow covers terminal CLI sessions.

Claude’s [settings precedence](https://code.claude.com/docs/en/settings) supports invocation overrides, and its [Foundry documentation](https://code.claude.com/docs/en/azure-ai-foundry) describes Azure CLI authentication through the native Azure credential chain.

If discovery reports an expired or invalid Azure login, reauthenticate with `az login` using the tenant/scope instructions Azure prints, then retry. A readable cached `az account show` alone does not confirm the login can access Foundry. Live inference has not yet been verified because Azure resource discovery rejected the cached login during implementation.
