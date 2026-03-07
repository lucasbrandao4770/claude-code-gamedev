# Godot Engine AI Tools, Plugins & Integrations — March 2026

> **Research date:** 2026-03-07
> **Scope:** MCP servers, Claude Code skills, editor plugins, in-game LLM tools, asset generators, community workflows

---

## Table of Contents

1. [Godot MCP Servers](#1-godot-mcp-servers)
2. [Claude Code Skills & Agents for Godot](#2-claude-code-skills--agents-for-godot)
3. [AI Plugins for the Godot Editor](#3-ai-plugins-for-the-godot-editor)
4. [In-Game LLM Integration (NPC Dialogue, etc.)](#4-in-game-llm-integration)
5. [AI Asset Generation Tools](#5-ai-asset-generation-tools)
6. [Godot + LLM Workflows & Tutorials](#6-godot--llm-workflows--tutorials)
7. [Community Tools & Utilities](#7-community-tools--utilities)
8. [Summary & Recommendations](#8-summary--recommendations)

---

## 1. Godot MCP Servers

The MCP (Model Context Protocol) ecosystem for Godot is surprisingly mature, with **11+ implementations** as of March 2026. MCP servers allow AI coding assistants (Claude Desktop, Claude Code, Cursor, Cline, Windsurf, etc.) to programmatically interact with the Godot editor — creating scenes, editing scripts, running projects, and capturing debug output.

### 1.1 Coding-Solo/godot-mcp — The Most Popular

| Attribute | Value |
|-----------|-------|
| **GitHub** | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) |
| **Stars** | ~2,200 |
| **Forks** | 247 |
| **Tech** | JavaScript (59%) + GDScript (41%), Node.js |
| **Godot** | 3.5+ and all 4.x |
| **License** | MIT |

**Features:**
- Launch Godot editor instances
- Run projects in debug mode with real-time output capture
- Create/modify scenes with customizable node types
- Load sprites/textures into 2D nodes
- Export 3D scenes as MeshLibrary
- UID management (Godot 4.4+)
- Automatic Godot installation detection
- Read-only mode for safe analysis

**Supported AI clients:** Cline, Roo Code, Cursor, VS Code, Claude Desktop, and any MCP-enabled tool.

**Assessment:** The de facto standard. Most forks, most stars, widest adoption. Solid choice for any workflow.

---

### 1.2 ee0pdt/Godot-MCP — Best Bidirectional Integration

| Attribute | Value |
|-----------|-------|
| **GitHub** | [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP) |
| **Stars** | ~484 |
| **Tech** | TypeScript (33%) + GDScript (66%) |
| **Godot** | 4.x |
| **License** | MIT |

**Features:**
- Full bidirectional communication between Claude and Godot editor
- Five command categories: Node, Script, Scene, Project, Editor
- AI can apply suggested changes directly in the editor in real-time
- Resource endpoints for current scripts, scenes, project metadata

**Assessment:** The most interactive implementation. If you want Claude to truly collaborate inside the editor (not just generate files), this is the one to try.

---

### 1.3 bradypp/godot-mcp — Clean Implementation

| Attribute | Value |
|-----------|-------|
| **GitHub** | [bradypp/godot-mcp](https://github.com/bradypp/godot-mcp) |
| **Stars** | ~55 |
| **Tech** | Node.js / TypeScript |
| **Godot** | 3.5+ and all 4.x |

**Features:** Similar to Coding-Solo but with UID management, 3D MeshLibrary export, and read-only mode. Good documentation.

---

### 1.4 tugcantopaloglu/godot-mcp — Maximum Engine Control (149 Tools)

| Attribute | Value |
|-----------|-------|
| **GitHub** | [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) |
| **Stars** | ~25 |
| **Tech** | TypeScript |
| **Godot** | 4.x |

**Features:** Fork that expands from 20 to **149 tools** covering:
- Runtime GDScript execution
- Real-time node inspection and manipulation
- Signal system management
- Physics queries, audio control, animation trees
- Networking (HTTP, WebSocket, multiplayer)
- Headless scene parsing without running the game

**Assessment:** Experimental but ambitious. Most comprehensive tool coverage. Good for power users who want full engine control from AI.

---

### 1.5 Dokujaa/Godot-MCP — Meshy 3D Integration

| Attribute | Value |
|-----------|-------|
| **GitHub** | [Dokujaa/Godot-MCP](https://github.com/Dokujaa/Godot-MCP) |
| **Stars** | ~37 |
| **Tech** | Python (54%) + GDScript (46%) |
| **Godot** | 4.x |
| **Updated** | 2026-03-07 |

**Unique feature:** Integrates with the **Meshy API** for AI-generated 3D mesh creation, dynamically importing them into Godot scenes. This is the only MCP that bridges AI 3D asset generation directly into the engine.

---

### 1.6 Other Notable MCP Servers

| Project | Stars | Highlight |
|---------|-------|-----------|
| [LeeSinLiang/godot-mcp](https://github.com/LeeSinLiang/godot-mcp) | 1 | Remote debugging via Godot's debugger ports (6006/6007) |
| [tomyud1/godot-mcp](https://github.com/tomyud1/godot-mcp) | — | 32 tools incl. 2D asset generation + project visualizer (also on [Asset Library](https://godotengine.org/asset-library/asset/4767)) |
| **[GDAI MCP](https://gdaimcp.com/)** | — | **Paid ($19 one-time)**. Screenshot capture, debugger parsing, asset-aware prompting. Most polished commercial offering. |

---

### MCP Server Comparison Matrix

| Feature | Coding-Solo | ee0pdt | tugcantopaloglu | Dokujaa | GDAI |
|---------|:-----------:|:------:|:---------------:|:-------:|:----:|
| Launch editor | Yes | Yes | Yes | Yes | Yes |
| Run/debug project | Yes | Yes | Yes | Yes | Yes |
| Create scenes | Yes | Yes | Yes | Yes | Yes |
| Edit scripts | Yes | Yes | Yes | Yes | Yes |
| Bidirectional editor comms | No | **Yes** | No | No | Yes |
| Runtime GDScript eval | No | No | **Yes** | No | No |
| 3D asset generation | No | No | No | **Yes** (Meshy) | No |
| Screenshot capture | No | No | No | No | **Yes** |
| Read-only mode | Yes | No | No | No | No |
| Price | Free | Free | Free | Free | $19 |
| Stars | ~2,200 | ~484 | ~25 | ~37 | — |

---

## 2. Claude Code Skills & Agents for Godot

### 2.1 Randroids-Dojo/Godot-Claude-Skills

| Attribute | Value |
|-----------|-------|
| **GitHub** | [Randroids-Dojo/Godot-Claude-Skills](https://github.com/Randroids-Dojo/Godot-Claude-Skills) |
| **Stars** | 13 |
| **Last commit** | December 2025 |

**What it includes:**
- GdUnit4 testing integration (unit, scene, input simulation tests)
- PlayGodot automation framework for end-to-end game testing
- Web and desktop export capabilities
- GitHub Actions CI/CD pipeline support
- Deployment tools for Vercel, GitHub Pages, itch.io
- Python helper scripts

**Installation:**
```bash
# Via marketplace
/plugin marketplace add Randroids-Dojo/Godot-Claude-Skills
/plugin install godot

# Manual: copy skills/godot to .claude/skills/
```

**Assessment:** The only dedicated Claude Code skill set for Godot. Focused on testing and CI/CD rather than content generation. Low adoption but useful as a starting point.

---

### 2.2 Skills on Marketplaces

Several Godot skills have appeared on skill marketplaces:

- **[FastMCP — godot skill](https://fastmcp.me/skills/details/235/godot)** — Basic Godot development skill
- **[mcpmarket — Godot Game Development](https://mcpmarket.com/tools/skills/godot-game-development-1)** — Code generation and debugging
- **[mcpmarket — Godot Scene Architect](https://mcpmarket.com/tools/skills/godot-scene-architect)** — Scene design specialist
- **[LobeHub — godot-dev](https://lobehub.com/skills/hubdev-ai-godot-ai-builder-godot-dev)** — AI builder for Godot

**Assessment:** Most are thin wrappers (system prompts) rather than deep skills. The Randroids-Dojo project is the most substantive.

---

### 2.3 Game Developer Subagent

Available at [buildwithclaude.com](https://www.buildwithclaude.com/subagent/game-developer), this subagent profile covers:
- Gameplay mechanics and systems architecture
- Unity, Unreal, and Godot development
- Physics simulation, collision detection, AI behavior systems

**Assessment:** Generic game dev agent, not Godot-specific. Useful as a reference for building your own.

---

## 3. AI Plugins for the Godot Editor

### 3.1 Code Assistant Plugins (In-Editor)

#### AI Assistant Hub (FlamxGames)

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [AI Assistant Hub](https://godotengine.org/asset-library/asset/3427) |
| **GitHub** | [FlamxGames/godot-ai-assistant-hub](https://github.com/FlamxGames/godot-ai-assistant-hub) |
| **Stars** | 217 |
| **Version** | 1.8.1 (March 2026) |
| **Godot** | 4.3 — 4.6 |
| **Price** | Free / MIT |

**Providers:** Ollama, Google Gemini, Jan, Ollama Turbo, OpenRouter, OpenWebUI, xAI

**Features:**
- AI writes code directly in Godot's code editor
- Read highlighted code for context
- Reusable prompt buttons
- Custom assistant types (no coding needed)
- Multiple simultaneous chat sessions
- Local or remote LLM support

**Assessment:** Most mature free in-editor assistant. Actively maintained, good community. Does NOT generate scenes — code-only.

---

#### AI Autonomous Agent (B1TBEAR)

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [AI Autonomous Agent](https://godotengine.org/asset-library/asset/4583) |
| **Version** | 1.0.2 (December 2025) |
| **Godot** | 4.0 |
| **Price** | Free / MIT |

**Providers:** Gemini, Ollama, OpenRouter, OpenWebUI

**Features:**
- **Autonomous multi-step tasks** with minimal user interaction
- Direct file system access (list, create, modify, delete)
- Live script editing and refactoring
- Scene creation and modification (.tscn)
- Automated error detection and correction
- Anti-hallucination safeguards

**Assessment:** The most "agentic" in-editor plugin. Can autonomously execute complex tasks. **Warning:** has write/delete permissions — use with Git version control.

---

#### Fuku (af009)

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [Fuku](https://godotengine.org/asset-library/asset/2689) |
| **GitHub** | [af009/fuku](https://github.com/af009/fuku) |
| **Godot** | 4.5 |
| **Price** | Free / MIT |

**Providers:** Ollama, OpenAI, Claude, Gemini, Docker Model Runner

**Features:** Multi-provider chat interface in the editor dock. Context-aware assistance. Simple chatbot — no code injection or scene editing.

**Assessment:** Good for quick Q&A inside the editor. Lightweight.

---

#### Itqan AI

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [Itqan AI](https://godotengine.org/asset-library/asset/4560) |
| **Godot** | 4.0 |
| **Price** | Free / MIT |

**Provider:** Google Gemini API only. Smart assistant for code writing, modification, and error fixing.

---

#### AlphaAgent

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [AlphaAgent](https://godotengine.org/asset-library/asset/4532) |
| **Version** | 0.4 (February 2026) |
| **Godot** | 4.5 |
| **Price** | Free / MIT |

AI assistant in the editor with chat interface, game debugging support, and performance optimization. Early stage.

---

#### AI Assistants For Godot 4 (GrandpaEJ)

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [AI Assistants For Godot 4](https://godotengine.org/asset-library/asset/4075) |
| **Version** | 3.0 (March 2026) |
| **Godot** | 4.0 |
| **Price** | Free / MIT |

Claims "professional-grade" status with responsive design and enhanced markdown highlighting. Limited documentation.

---

#### Godot AI Hook

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [Godot AI Hook](https://godotengine.org/asset-library/asset/4677) |
| **Version** | 1.0.1 |
| **Godot** | 4.5 |
| **Price** | Free / MIT |

OpenAI Chat Completions protocol integration for in-game dialogue. Supports DeepSeek and Doubao. More of a runtime tool than an editor assistant.

---

### 3.2 Code Completion Plugins (Copilot-Style)

#### Godot Copilot (minosvasilias)

| Attribute | Value |
|-----------|-------|
| **GitHub** | [minosvasilias/godot-copilot](https://github.com/minosvasilias/godot-copilot) |
| **Stars** | 287 |
| **Last commit** | March 2023 |
| **Godot** | 3.x and 4.x |

Uses OpenAI APIs for code completion at caret position via keyboard shortcut. **Abandoned** (last commit March 2023). GDScript is underrepresented in OpenAI's training data, so quality is limited.

---

#### copilot.gd (lrdcxdes) — GitHub Copilot Integration

| Attribute | Value |
|-----------|-------|
| **GitHub** | [lrdcxdes/copilot.gd](https://github.com/lrdcxdes/copilot.gd) |
| **Stars** | 13 |
| **Last commit** | February 2026 |
| **Godot** | 4.6 |
| **Requires** | Node.js 20.8+, GitHub Copilot subscription |

**Features:**
- Ghost text suggestions as you type (configurable delay)
- Tab to accept, Esc to dismiss
- Supports .gd, .cs, .glsl files
- Session persistence across restarts

**Assessment:** The only real "GitHub Copilot in Godot" experience. Actively maintained. Requires Node.js bridge.

---

#### Copilot/CodeCompletion (Gemini, LMStudio, Ollama)

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [Copilot/CodeCompletion](https://godotengine.org/asset-library/asset/3279) |

Self-hostable code completion using Gemini, LMStudio, or Ollama. Allows local model usage.

---

### 3.3 Paid / Commercial Plugins

#### Ziva

| Attribute | Value |
|-----------|-------|
| **Website** | [ziva.sh](https://ziva.sh/) |
| **Pricing** | Free (20 credits), Pro ($20/mo, 500 prompts), Pay-as-you-go ($10/250 credits) |
| **Godot** | 4.2+ |

**Features:** GDScript code generation, scene creation, project understanding, debugger integration, UI agent specialization.

**Assessment:** The most polished commercial Godot-specific AI tool. Native editor integration. Worth evaluating if budget allows.

---

#### Godot AI Suite (MarcEngel)

| Attribute | Value |
|-----------|-------|
| **itch.io** | [Godot AI Suite](https://marcengelgamedevelopment.itch.io/godot-ai-suite) |
| **Version** | 2.0 |

**Features:**
- Generates a "Masterprompt" containing your entire project context (GDD, devlogs, project settings, scene trees, full codebase)
- **Talk Mode:** consulting, brainstorming, advice
- **Agent Mode:** AI responds with JSON execution plan that the plugin auto-executes (create scripts, refactor code, modify scenes, change settings)
- Supports Gemini, Claude, ChatGPT
- Fully customizable prompts

**Assessment:** Creative approach. The Masterprompt concept is powerful for context-heavy AI interactions. The Agent Mode is experimental but interesting.

---

## 4. In-Game LLM Integration

These tools embed LLMs inside shipped games for NPC dialogue, procedural content, etc.

### 4.1 NobodyWho — Local LLMs for Games

| Attribute | Value |
|-----------|-------|
| **GitHub** | [nobodywho-ooo/nobodywho](https://github.com/nobodywho-ooo/nobodywho) |
| **Stars** | 718 |
| **Godot** | 4.5+ (AssetLib) |
| **Platforms** | Windows, Linux, macOS, Android |
| **Last release** | March 2026 |

**Features:**
- Run any GGUF-format LLM completely offline
- Tool calling with automatic grammar derivation
- Context-aware conversation management
- GPU-accelerated inference (Vulkan/Metal)
- Also available for Python and Flutter

**Assessment:** The most mature local-LLM-in-game solution. 718 stars, active development, multi-platform. Great for shipping games with AI NPCs.

---

### 4.2 GDLlama — GDExtension for llama.cpp

| Attribute | Value |
|-----------|-------|
| **GitHub** | [xarillian/GDLlama](https://github.com/xarillian/GDLlama) |
| **Stars** | 9 |
| **Version** | 1.0.1-stable (October 2025) |
| **Godot** | 4.4+ |

**Features:**
- Custom GDLlama node for any scene
- Conversational AI with context preservation
- Function calling with JSON schema/GBNF constraints
- Real-time streaming via signals
- Embedding support for semantic search
- Vulkan GPU acceleration

**Assessment:** Lower-level than NobodyWho but more control. Fork/continuation of godot-llm. Good for developers who want fine-grained control.

---

### 4.3 godot-llm (Adriankhl) — Original LLM Plugin

| Attribute | Value |
|-----------|-------|
| **GitHub** | [Adriankhl/godot-llm](https://github.com/Adriankhl/godot-llm) |
| **Stars** | 236 |
| **Last commit** | May 2024 |

**Features:** GDLlama (text), GDEmbedding (embeddings), GDLlava (multimodal/vision), LlmDB (vector DB for RAG). Built on llama.cpp.

**Assessment:** The pioneer. No longer actively maintained — use GDLlama or NobodyWho instead.

---

### 4.4 Beehave — Behavior Trees (Non-LLM AI)

| Attribute | Value |
|-----------|-------|
| **GitHub** | [bitbrain/beehave](https://github.com/bitbrain/beehave) |
| **Asset Library** | [Beehave](https://godotengine.org/asset-library/asset/1349) |

Traditional behavior tree addon for NPC AI. Not LLM-based but worth mentioning as the standard for game AI in Godot. Well-established, widely used.

---

### 4.5 Player2 AI NPC

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [Player2 AI NPC](https://godotengine.org/asset-library/asset/4097) |

Create AI NPCs using free APIs from the Player2 App. Cloud-based, no local model needed.

---

## 5. AI Asset Generation Tools

### 5.1 PixelLab — AI Pixel Art with MCP

| Attribute | Value |
|-----------|-------|
| **Website** | [pixellab.ai](https://www.pixellab.ai/) |
| **MCP** | [pixellab-code/pixellab-mcp](https://github.com/pixellab-code/pixellab-mcp) |

**Features:**
- Generate pixel art characters, animations, tilesets from text
- Directional rotation (4 or 8 directions)
- AI animation (walk, run, attack)
- Map & tileset generation
- MCP server for integration with Claude Code / Cursor ("vibe coding")

**Assessment:** The leading AI pixel art tool. The MCP integration means you can generate sprites from within your AI coding workflow. Works with any engine including Godot.

---

### 5.2 3D AI Studio — Godot-Ready 3D Assets

| Attribute | Value |
|-----------|-------|
| **Website** | [3daistudio.com/UseCases/Godot](https://www.3daistudio.com/UseCases/Godot) |

Text or image to Godot-ready 3D assets with clean topology and PBR materials. Export and add to Godot scenes.

---

### 5.3 ArmorLab — Open Source Texture Generator

Open source, runs locally. Extracts full PBR maps from photos and generates seamless materials from text prompts. No cloud subscription needed.

---

### 5.4 Sprite-AI

| Attribute | Value |
|-----------|-------|
| **Website** | [sprite-ai.art](https://www.sprite-ai.art/) |

Generate pixel art sprites from text with exact pixel sizes. Godot-compatible output.

---

## 6. Godot + LLM Workflows & Tutorials

### 6.1 Blog Posts & Articles

| Title | Author | Key Takeaway |
|-------|--------|-------------|
| [Building an RTS in Godot — Claude Writes ALL Code](https://dev.to/datadeer/part-1-building-an-rts-in-godot-what-if-claude-writes-all-code-49f9) | datadeer | Claude (Sonnet 4) generates features in <5 min but precision of prompts matters. Full delegation caused "cognitive disconnection" — hybrid approach recommended. |
| [Running Local LLMs in Godot + Ollama](https://dev.to/ykbmck/running-local-llms-in-game-engines-heres-my-journey-with-godot-ollama-4hhd) | ykbmck | Godot's HTTPRequest nodes make LLM connection straightforward. Separate inference server preferred over in-engine. |
| [An AI Engineer's Guide to godot-mcp](https://skywork.ai/skypage/en/An-AI-Engineer's-Guide-to-godot-mcp-Bridging-Generative-AI-and-Game-Development/1972589190641152000) | Skywork AI | Deep technical dive into MCP architecture for Godot. |
| [I Made a Game with AI](https://www.kevinlondon.com/2025/06/04/building-game-with-ai/) | Kevin London | Real experience report of AI-assisted Godot game development. |
| [Integrate AI Models in Godot 4.5 with GDScript in 20 Minutes](https://markaicode.com/godot-gdscript-ai-integration/) | Markaicode | Step-by-step tutorial for HTTP-based AI integration. |

### 6.2 YouTube

- **"AI Builds a Godot Game From Scratch | PixelLab MCP + Claude Code Workflow"** by Nikolai (Oct 2025) — Demonstrates full vibe-coding workflow with Claude Code + PixelLab MCP for asset generation + Godot MCP for engine control.

### 6.3 Godot Engine Proposals

- [Integrating LLM Output into Godot with Structured Rendering](https://github.com/godotengine/godot-proposals/issues/13467) — Proposal for native LLM output rendering in the engine (tutorials, dialogue, procedural content). Shows the community is thinking about first-class LLM support.

---

## 7. Community Tools & Utilities

### 7.1 AI Context Generator

| Attribute | Value |
|-----------|-------|
| **Asset Library** | [AI Context Generator](https://godotengine.org/asset-library/asset/4182) |
| **Author** | mickey |

Exports your entire Godot project structure as JSON for AI/LLM analysis. One-click generation with clipboard integration. Great for feeding project context to any AI assistant.

---

### 7.2 Workik Godot Code Generator

| Attribute | Value |
|-----------|-------|
| **Website** | [workik.com/godot-code-generator](https://workik.com/godot-code-generator) |

Web-based AI code generation with GDScript support. Free tier available. No editor integration (copy-paste workflow).

---

### 7.3 RAG with Godot — Fully Local Agent

| Attribute | Value |
|-----------|-------|
| **Article** | [Medium — RAG with Godot](https://igorcomune.medium.com/rag-with-godot-fully-local-open-source-agent-for-game-development-429266298e79) |

Demonstrates building a fully local, open-source agent for Godot game development using Retrieval-Augmented Generation (RAG) — indexing Godot documentation for context-aware code generation.

---

## 8. Summary & Recommendations

### Maturity Tiers

**Production-Ready (use confidently):**
- Coding-Solo/godot-mcp (2.2k stars, widely adopted)
- AI Assistant Hub (217 stars, v1.8.1, active)
- NobodyWho (718 stars, multi-platform, for in-game LLMs)
- Beehave (behavior trees, industry standard)

**Promising / Active Development:**
- ee0pdt/Godot-MCP (bidirectional, 484 stars)
- PixelLab MCP (AI pixel art generation)
- AI Autonomous Agent (agentic editor plugin)
- Godot AI Suite 2.0 (Masterprompt + Agent mode)
- copilot.gd (GitHub Copilot in Godot)
- GDLlama (local LLM GDExtension)
- Ziva (commercial, polished)

**Early / Experimental:**
- tugcantopaloglu/godot-mcp (149 tools, ambitious)
- Dokujaa/Godot-MCP (Meshy 3D integration)
- Randroids-Dojo/Godot-Claude-Skills (13 stars, testing-focused)
- AlphaAgent, Itqan AI, Fuku (lightweight assistants)

**Abandoned / Legacy:**
- minosvasilias/godot-copilot (last commit March 2023)
- Adriankhl/godot-llm (superseded by GDLlama/NobodyWho)

### Recommended Stack for Different Use Cases

**For AI-assisted Godot development (external AI coding):**
1. Install **Coding-Solo/godot-mcp** or **ee0pdt/Godot-MCP** for MCP bridge
2. Use **Claude Code** or **Cursor** as the AI coding assistant
3. Add **AI Context Generator** plugin for project context export
4. Use **PixelLab MCP** for sprite/asset generation

**For in-editor AI assistance:**
1. **AI Assistant Hub** (free, multi-provider) or **Ziva** (paid, polished)
2. **copilot.gd** for GitHub Copilot-style inline completion
3. **AI Autonomous Agent** for agentic multi-step automation

**For shipping games with AI NPCs:**
1. **NobodyWho** (offline, GPU-accelerated, most mature)
2. **GDLlama** (more control, GDExtension)
3. **Godot AI Hook** (cloud-based, OpenAI-compatible APIs)

---

## Sources

- [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)
- [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP)
- [bradypp/godot-mcp](https://github.com/bradypp/godot-mcp)
- [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp)
- [Dokujaa/Godot-MCP](https://github.com/Dokujaa/Godot-MCP)
- [LeeSinLiang/godot-mcp](https://github.com/LeeSinLiang/godot-mcp)
- [GDAI MCP](https://gdaimcp.com/)
- [Randroids-Dojo/Godot-Claude-Skills](https://github.com/Randroids-Dojo/Godot-Claude-Skills)
- [FlamxGames/godot-ai-assistant-hub](https://github.com/FlamxGames/godot-ai-assistant-hub)
- [AI Autonomous Agent](https://godotengine.org/asset-library/asset/4583)
- [Fuku](https://godotengine.org/asset-library/asset/2689)
- [Itqan AI](https://godotengine.org/asset-library/asset/4560)
- [AlphaAgent](https://godotengine.org/asset-library/asset/4532)
- [AI Assistants For Godot 4](https://godotengine.org/asset-library/asset/4075)
- [Godot AI Hook](https://godotengine.org/asset-library/asset/4677)
- [AI Context Generator](https://godotengine.org/asset-library/asset/4182)
- [Godot AI Assistant tools MCP](https://godotengine.org/asset-library/asset/4767)
- [minosvasilias/godot-copilot](https://github.com/minosvasilias/godot-copilot)
- [lrdcxdes/copilot.gd](https://github.com/lrdcxdes/copilot.gd)
- [Copilot/CodeCompletion](https://godotengine.org/asset-library/asset/3279)
- [Ziva](https://ziva.sh/blogs/best-ai-tools-for-godot-game-engine)
- [Godot AI Suite](https://marcengelgamedevelopment.itch.io/godot-ai-suite)
- [nobodywho-ooo/nobodywho](https://github.com/nobodywho-ooo/nobodywho)
- [xarillian/GDLlama](https://github.com/xarillian/GDLlama)
- [Adriankhl/godot-llm](https://github.com/Adriankhl/godot-llm)
- [bitbrain/beehave](https://github.com/bitbrain/beehave)
- [Player2 AI NPC](https://godotengine.org/asset-library/asset/4097)
- [PixelLab](https://www.pixellab.ai/)
- [pixellab-code/pixellab-mcp](https://github.com/pixellab-code/pixellab-mcp)
- [3D AI Studio](https://www.3daistudio.com/UseCases/Godot)
- [Sprite-AI](https://www.sprite-ai.art/)
- [Workik Godot Code Generator](https://workik.com/godot-code-generator)
- [FastMCP — godot skill](https://fastmcp.me/skills/details/235/godot)
- [mcpmarket — Godot Game Development](https://mcpmarket.com/tools/skills/godot-game-development-1)
- [Building an RTS with Claude](https://dev.to/datadeer/part-1-building-an-rts-in-godot-what-if-claude-writes-all-code-49f9)
- [Running Local LLMs in Godot + Ollama](https://dev.to/ykbmck/running-local-llms-in-game-engines-heres-my-journey-with-godot-ollama-4hhd)
- [Godot LLM Proposal #13467](https://github.com/godotengine/godot-proposals/issues/13467)
- [RAG with Godot](https://igorcomune.medium.com/rag-with-godot-fully-local-open-source-agent-for-game-development-429266298e79)
- [PulseMCP Godot Servers](https://www.pulsemcp.com/servers?q=godot)
