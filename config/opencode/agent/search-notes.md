# Knowledge Retrieval Agent

**Command:** `/search-notes`  
**Aliases:** `/knowledge`, `/kn`  
**Provider:** Anthropic Claude Sonnet + OpenAI Embeddings  
**Type:** Secondary Agent

## Purpose

Semantic search across Obsidian vault and Readwise highlights using hybrid keyword + embedding retrieval with source citations.

## Configuration

```yaml
model:
  provider: anthropic
  name: claude-opus-4-6
  temperature: 0.1
  max_tokens: 4096

embeddings:
  provider: openai
  model: text-embedding-3-small
  dimension: 1536
  index_type: faiss

search:
  strategy: hybrid
  keyword_weight: 0.4
  embedding_weight: 0.6
  max_results: 10
  min_relevance_score: 0.7
  reranking: true
```

## Index Paths

- `~/notes/SecondBrain/**/*.md` (Obsidian vault)
- `~/.config/opencode/indices/readwise.db` (Readwise highlights)

## Search Strategy

### Hybrid Retrieval
1. **Keyword Search (BM25)**: 40% weight
2. **Semantic Search (Embeddings)**: 60% weight
3. **Reranking**: Cross-encoder for final scoring

### Indexing

- **Mode**: Incremental
- **Watch**: File system events
- **Schedule**: Every 30 minutes
- **Chunk size**: 512 tokens
- **Chunk overlap**: 50 tokens

## System Prompt

```
You are a knowledge retrieval assistant with access to personal notes and highlights.

Your role:
- Search across notes using hybrid keyword + semantic matching
- Synthesize information from multiple sources
- Cite sources with file paths and context
- Highlight relevant quotes
- Suggest related topics for exploration

Always include source references.
```

## Output Format

```markdown
# Search Results: "How do I configure Azure APIM?"

## Summary
Azure API Management (APIM) can be configured through ARM templates, Azure CLI, or the portal. Key components include API definitions, policies, and backend services.

## Key Findings

### Configuration Methods
**Source:** `azure/api-management.md:23`

> Azure APIM supports three primary configuration methods:
> 1. Azure Portal (GUI)
> 2. ARM Templates (IaC)
> 3. Azure CLI (scripting)

The ARM template approach is recommended for production deployments.

### Policy Configuration
**Source:** `azure/apim-policies.md:45`

> APIM policies are XML-based and applied at different scopes:
> - Global scope
> - Product scope
> - API scope
> - Operation scope

Example inbound policy:
```xml
<inbound>
  <rate-limit calls="100" renewal-period="60" />
  <set-header name="X-API-Version" exists-action="override">
    <value>v2</value>
  </set-header>
</inbound>
```

### Backend Service Integration
**Source:** Readwise > "Azure Architecture Guide" (highlighted 2024-01-15)

> "When integrating backend services with APIM, use named values for 
> environment-specific configuration and managed identities for 
> authentication to avoid storing credentials."

## Related Topics
- Azure Policy as Code
- API Gateway Patterns
- Managed Identity Setup

## Additional Sources
1. `azure/networking.md` - VNet integration
2. `devops/terraform-modules.md` - APIM Terraform module
3. Readwise > "Cloud Design Patterns" - API Gateway pattern
```

## Usage

```bash
# Search notes
/search-notes "How do I configure Azure APIM?"

# Quick alias
/knowledge "DevSecOps best practices"

# Short form
/kn "terraform state management"
```

## Index Management

### Initial Build
```bash
# Build FAISS index from scratch
opencode index build --source ~/notes/SecondBrain

# Import Readwise highlights
opencode index import --readwise --token $READWISE_TOKEN
```

### Incremental Updates
```bash
# Watch for changes (runs automatically)
opencode index watch

# Force rebuild
opencode index rebuild
```

### Index Stats
```bash
opencode index stats

# Output:
# Documents indexed: 2,847
# Chunks: 15,234
# Index size: 248 MB
# Last updated: 2024-10-17 22:15:32
```

## Rate Limiting

- **Requests per minute**: 30
- **Burst size**: 10

## Caching

- **Enabled**: Yes
- **TTL**: 1800 seconds (30 minutes)

## Storage

- **Index**: `~/.config/opencode/indices/knowledge.faiss`
- **Metadata**: `~/.config/opencode/indices/knowledge.db` (SQLite)

## Environment Variables

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
export OPENAI_API_KEY="your-openai-key"

# Optional
export READWISE_TOKEN="your-readwise-token"
```

## Capabilities

- Semantic search
- Keyword search (BM25)
- Embedding retrieval (FAISS)
- Multi-source synthesis
- Source citation
