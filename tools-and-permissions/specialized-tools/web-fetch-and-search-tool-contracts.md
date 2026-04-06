---
title: "Web Fetch and Search Tool Contracts"
owners: []
soft_links: [/tools-and-permissions/tool-catalog/tool-families.md, /tools-and-permissions/permissions/permission-model.md, /tools-and-permissions/specialized-tools/browser-automation-and-native-computer-use.md, /integrations/mcp/server-contract.md]
---

# Web Fetch and Search Tool Contracts

Claude Code treats plain web access as its own read-only tool family. A faithful rebuild needs two separate contracts: one for fetching a known URL and extracting usable content, and another for doing provider-backed web search for current information.

## Fetch and search are separate tools

Equivalent behavior should preserve:

- one URL-fetch surface for "I already know the page"
- one search surface for "I need to discover current sources"
- both tools being read-only and concurrency-safe
- both tools remaining distinct from authenticated browser automation or MCP-backed access to private systems

## Web fetch contract

Equivalent behavior should preserve:

- per-domain permissioning rather than one blanket "internet yes/no" check
- a preapproved-host path for known-safe public domains
- explicit warnings that authenticated or private URLs should use specialized MCP or browser-backed surfaces instead of plain fetch
- redirect handling that notices cross-host redirects and surfaces them as a new fetch decision rather than silently following into a different permission domain
- content extraction that returns a processed result plus enough fetch metadata to explain what happened

## Web search contract

Equivalent behavior should preserve:

- provider-aware enablement, because not every model/provider envelope supports the same server-side search path
- optional allowlist or blocklist domain filters on a per-call basis
- a bounded multi-search backend behavior per request rather than an unlimited crawl
- results that can include both structured search hits and model-generated commentary or synthesis around those hits
- a permission flow that stays inside the normal tool approval system even when the search backend itself is provider-native

## Separation from companion and MCP surfaces

Equivalent behavior should preserve:

- plain fetch/search staying available without authenticated browser state
- authenticated or private-site access being deferred to browser automation, Chrome companion, or specialized MCP tools
- the model being steered toward those richer surfaces when plain fetch is expected to fail

## Failure modes

- **private-url confusion**: the model uses plain fetch on an authenticated or private system and gets a misleading failure instead of being redirected toward MCP or browser-backed access
- **redirect domain leak**: a cross-host redirect is silently followed without re-evaluating permissions for the destination host
- **tool-family collapse**: fetch, search, and authenticated browser control are merged into one generic web tool and lose their different safety and capability boundaries
- **provider drift**: web search is offered under providers or model envelopes that cannot actually execute it
