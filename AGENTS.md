# KrakenAI - OpenTTD AI Agent

KrakenAI is an artificial intelligence agent designed for [OpenTTD](https://www.openttd.org/), an open-source simulation game based on the classic business simulation game Transport Tycoon Deluxe.

## About KrakenAI

KrakenAI is an AI player that competes in OpenTTD by building and managing a truck-based transportation network. The agent uses strategic planning to:

- Identify profitable cargo routes between industries
- Construct road networks to connect pickup and drop-off stations
- Build and manage fleets of trucks to transport cargo
- Adapt vehicle counts based on station capacity and cargo demand
- Persist game state across saves and loads

## How It Works

The AI operates through a planning system where:

1. **Plan Selection** - Evaluates available industries and cargo types to select the most profitable routes
2. **Action Execution** - Breaks down plans into discrete actions (building stations, roads, depots, and vehicles)
3. **Background Tasks** - Continuously optimizes vehicle counts and manages fleet efficiency during idle time

## Integration with OpenTTD

KrakenAI is implemented as an OpenTTD NoAI Script and uses:
- **OpenTTD AI API** - For all game interactions and queries. Full API documentation available at: https://docs.openttd.org/ai-api/annotated
- **SuperLib** - A utility library for common AI operations
- **Custom pathfinding** - For efficient road construction between stations