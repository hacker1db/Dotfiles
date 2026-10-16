# Rendering and embedding

Use an available draw.io export capability that embeds diagram data, or render and embed with compatible local helpers. Verify current command syntax before use. Resolve helper paths from the repository or user configuration; do not assume a particular home directory, host, or package manager.

The dotfiles distribution may provide `claude/drawio-scripts/render_drawio_html.js` and `claude/drawio-scripts/embed_xml.js`. Inspect the scripts and dependency manifest at the resolved location. Install missing declared dependencies only when needed. With compatible helpers, the sequence is:

```sh
node <resolved-render-helper> <source.drawio> <preview.html> 0
```

Capture a PNG from the rendered preview using an available browser screenshot capability, then run:

```sh
node <resolved-embed-helper> <rendered.png> <source.drawio> <editable.png>
```

Both helpers only read and write files under the current working directory (or `DRAWIO_ALLOWED_DIR` when set), refuse symlinks that escape it, and require `.drawio`/`.xml`, `.html`, and `.png` extensions as appropriate. Run them from the directory that holds the diagram and outputs.

Confirm PNG signature, rendered image content, and embedded diagram XML. Opening the exported PNG in draw.io should restore editable cells. XML structure validation alone cannot confirm that the PNG is editable.

Use the complete legend XML in `component-styles.md`. No external template file is required.
