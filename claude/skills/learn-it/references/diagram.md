# Excalidraw diagram contract

Create `<vault>/4.Resources/Excalidraw/[TOPIC] - 30 Min Learn - [YYYY-MM-DD].excalidraw.md` after the quiz. Read `../assets/concept-diagram.json` as the scene template and substitute the topic, step labels, and insight. Use one rectangle and label per actual mechanism step, with even spacing. Keep the insight background `#ffd43b`.

Adjust the scene to the actual content rather than retaining unused placeholders. Set valid geometry and supported Excalidraw element defaults for the installed renderer. Maintain unique IDs, matching container and bound element references, and valid arrow endpoints. Ensure text fits its shapes.

The Obsidian wrapper has frontmatter `excalidraw-plugin: parsed` and `tags: [excalidraw]`, followed by the view hint, `# Excalidraw Data`, and `## Text Elements`. In Text Elements, include each displayed label with a block identifier matching its text element ID. Then place `## Drawing` and a fenced `json` block containing the scene inside a `%%` comment block. This uncompressed JSON format is the required default.

Verify the JSON parses and all references resolve before linking the file from the note. Open a supported renderer when available to inspect layout. Do not claim rendering was checked based only on JSON parsing. If the plugin is unavailable, save the scene as standalone `.excalidraw` JSON in the vault root and link that actual file from the note. Report the actual saved format and path.
