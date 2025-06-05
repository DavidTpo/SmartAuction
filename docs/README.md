## ⚙️ Core Mechanics  

### Time Extension Logic  
```mermaid
sequenceDiagram
    Bidder->>Contract: Bid in last 10 minutes
    Contract->>Contract: Extends `endTime` by 10 minutes
