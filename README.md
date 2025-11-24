# PredictionMarket - Decentralized Prediction Markets

A trustless, blockchain-based prediction market platform built on the Stacks blockchain, enabling users to bet on future events, create markets, resolve outcomes through oracles, and earn from accurate predictions with transparent odds and automated payouts.

## Overview

PredictionMarket democratizes forecasting and information aggregation by allowing anyone to create prediction markets for real-world events. The platform leverages blockchain transparency, oracle-based resolution, and dynamic odds calculation to create a fair, efficient marketplace for predictions across politics, sports, finance, technology, and more.

## Key Features

### For Traders
- **Binary Predictions**: Bet YES or NO on future events
- **Dynamic Odds**: Real-time odds based on pool distribution
- **Multiple Positions**: Place multiple bets on same or different markets
- **Performance Tracking**: Win rate, wagered, and earnings statistics
- **Automated Payouts**: Claim winnings after market resolution
- **Risk Management**: See odds at entry for each position

### For Market Creators
- **Custom Markets**: Create markets on any yes/no question
- **Oracle Selection**: Choose trusted oracles for resolution
- **Category Organization**: Classify markets by topic
- **Deadline Control**: Set trading and resolution deadlines
- **Market Cancellation**: Cancel unresolved markets if needed
- **Creator Flexibility**: No fees or restrictions on market creation

### For Oracles
- **Resolution Authority**: Determine official market outcomes
- **Reputation System**: Build trust through accurate resolutions
- **Dispute Tracking**: Monitor challenges to your resolutions
- **Registration**: Establish oracle profile before resolving
- **Active Status**: Control availability for new markets
- **Reputation Rewards**: +5 reputation per resolution

### Platform Features
- **Automated Odds**: Dynamic calculation based on pool sizes
- **Payout Formula**: Proportional winnings from total pool
- **Dispute Mechanism**: Challenge questionable resolutions
- **Category Statistics**: Track volume and markets per category
- **Global Analytics**: Platform-wide volume and market count
- **Transparent Pools**: All betting pools visible on-chain

## Market Lifecycle

```
1. Oracle Registration
   ↓
2. Market Creation (with oracle, deadlines)
   ↓
3. Trading Period (place bets)
   ↓
4. Trading Deadline Passes
   ↓
5. Resolution Deadline Passes
   ↓
6. Oracle Resolves (YES or NO)
   ↓
7. Winners Claim Payouts
   ↓
8. Disputes (optional)
```

## Economic Model

### Pool Mechanics
```
Total Pool = YES Pool + NO Pool
Each bet adds to: Total Pool + Respective Side Pool
```

### Odds Calculation
```
YES Odds = (Total Pool × 100) / YES Pool
NO Odds = (Total Pool × 100) / NO Pool

Example:
Total: 1,000 STX
YES: 600 STX (60%)
NO: 400 STX (40%)

YES Odds: 167 (1.67x return)
NO Odds: 250 (2.5x return)
```

### Payout Formula
```
Winner Payout = (Bet Amount × Total Pool) / Winning Pool

Example:
Bet: 100 STX on NO
Outcome: NO wins
Total Pool: 1,000 STX
NO Pool: 400 STX
Payout: (100 × 1,000) / 400 = 250 STX
```

### Oracle Reputation
```
Starting Reputation: 100
Per Resolution: +5
Per Dispute: -10
Minimum: 0 (no negative)
```

## Smart Contract Functions

### Public Functions

#### Oracle Management

**register-oracle**
```clarity
(register-oracle (name (string-ascii 64)))
```
Registers caller as market oracle.
- Parameters: Oracle name/identifier
- Initial Reputation: 100
- Initial Status: Active
- Required: Before resolving any markets

#### Market Operations

**create-market**
```clarity
(create-market (question (string-ascii 256)) 
               (description (string-ascii 512)) 
               (category (string-ascii 32)) 
               (resolution-deadline uint) 
               (trading-duration uint) 
               (oracle principal))
```
Creates a new prediction market.
- Question: Yes/no question (max 256 chars)
- Description: Additional context (max 512 chars)
- Category: Market classification
- Resolution Deadline: Block height when oracle can resolve
- Trading Duration: How long bets can be placed
- Oracle: Designated resolver address
- Returns: Unique market ID
- Validation: Oracle must exist, resolution-deadline > current block

**place-bet**
```clarity
(place-bet (market-id uint) (prediction bool) (amount uint))
```
Places a bet on a market outcome.
- Market ID: Target market
- Prediction: true (YES) or false (NO)
- Amount: Bet size in base units
- Returns: Unique position ID
- Restrictions: Before trading deadline, market not resolved, amount > 0
- Updates: Pool totals, odds, trader statistics
- Records: Odds at entry for fair payout

**resolve-market**
```clarity
(resolve-market (market-id uint) (outcome bool))
```
Resolves a market with final outcome (oracle only).
- Authorization: Designated oracle only
- Timing: After resolution deadline
- Outcome: true (YES) or false (NO)
- Effect: Marks market resolved, enables claims
- Updates: Oracle reputation (+5), markets resolved count
- Immutable: Cannot be changed once resolved

**claim-winnings**
```clarity
(claim-winnings (position-id uint))
```
Claims payout from winning position.
- Authorization: Position owner only
- Requirements: Market resolved, not already claimed
- Calculation: Proportional to bet in winning pool
- Updates: Trader total won, position claimed status
- Returns: Payout amount (0 if lost)

**dispute-resolution**
```clarity
(dispute-resolution (market-id uint) (reason (string-ascii 256)))
```
Disputes an oracle's market resolution.
- Market ID: Target market
- Reason: Explanation for dispute (max 256 chars)
- Effect: Increments oracle dispute count, reduces reputation (-10)
- Purpose: Community-driven quality control
- Open to: Any user

**cancel-market**
```clarity
(cancel-market (market-id uint))
```
Cancels unresolved market (creator only).
- Authorization: Market creator only
- Timing: Before trading deadline
- Requirements: Not yet resolved
- Effect: Marks resolved with no outcome (refunds possible)
- Use Case: Market becomes obsolete or problematic

### Read-Only Functions

**get-market**
```clarity
(get-market (market-id uint))
```
Retrieves complete market information including pools and status.

**get-position**
```clarity
(get-position (position-id uint))
```
Returns position details including odds at entry and claim status.

**get-trader-stats**
```clarity
(get-trader-stats (trader principal))
```
Returns trader statistics: wagered, won, markets traded, win rate.

**get-oracle-profile**
```clarity
(get-oracle-profile (oracle principal))
```
Returns oracle information: reputation, markets resolved, disputes.

**get-current-odds**
```clarity
(get-current-odds (market-id uint) (prediction bool))
```
Calculates current odds for YES or NO on a market.
- Returns: Odds as percentage (e.g., 167 = 1.67x)

**get-platform-stats**
```clarity
(get-platform-stats)
```
Returns platform-wide statistics: total volume, total markets.

## Data Structures

### Market
```clarity
{
  creator: principal,
  question: (string-ascii 256),
  description: (string-ascii 512),
  category: (string-ascii 32),
  total-pool: uint,
  yes-pool: uint,
  no-pool: uint,
  resolution-deadline: uint,
  trading-deadline: uint,
  resolved: bool,
  outcome: (optional bool),
  oracle: principal,
  created-at: uint
}
```

### Position
```clarity
{
  market-id: uint,
  trader: principal,
  prediction: bool,
  amount: uint,
  odds-at-entry: uint,
  claimed: bool,
  created-at: uint
}
```

### Trader Statistics
```clarity
{
  total-wagered: uint,
  total-won: uint,
  markets-traded: uint,
  win-rate: uint
}
```

### Oracle Registry
```clarity
{
  name: (string-ascii 64),
  reputation: uint,
  markets-resolved: uint,
  disputes: uint,
  active: bool
}
```

**Default Values**: Reputation: 100, Markets: 0, Disputes: 0, Active: true

### Market Categories
```clarity
{
  total-markets: uint,
  total-volume: uint
}
```
Keyed by: Category name (string-ascii 32)

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | err-owner-only | Operation restricted to contract owner |
| u101 | err-not-found | Market, position, or oracle not found |
| u102 | err-unauthorized | Caller not authorized for this action |
| u103 | err-market-closed | Market closed for trading or resolution |
| u104 | err-invalid-amount | Invalid bet amount (zero or negative) |
| u105 | err-already-resolved | Market already resolved |
| u106 | err-not-resolved | Market not yet resolved |

## Usage Examples

### Complete Market Flow

**1. Register as Oracle**
```clarity
(contract-call? .prediction-market register-oracle 
  "TrustedSports Oracle")
;; Returns: (ok true)
;; Reputation: 100
```

**2. Create Market**
```clarity
(contract-call? .prediction-market create-market 
  "Will Bitcoin reach $100k by end of 2024?" 
  "Market resolves YES if Bitcoin (BTC) trades at or above $100,000 USD on any major exchange before Dec 31, 2024 11:59 PM UTC" 
  "Cryptocurrency" 
  u52560 ;; ~1 year resolution deadline
  u10080 ;; ~1 week trading period
  'SP2ORACLE...)
;; Returns: (ok u1)
```

**3. Traders Place Bets**
```clarity
;; Trader A bets YES
(contract-call? .prediction-market place-bet 
  u1 
  true 
  u500000000) ;; 500 STX on YES
;; Returns: (ok u1)

;; Trader B bets NO
(contract-call? .prediction-market place-bet 
  u1 
  false 
  u300000000) ;; 300 STX on NO
;; Returns: (ok u2)

;; Trader C bets YES
(contract-call? .prediction-market place-bet 
  u1 
  true 
  u200000000) ;; 200 STX on YES
;; Returns: (ok u3)

;; Pools: YES 700, NO 300, Total 1000
```

**4. Check Current Odds**
```clarity
(contract-call? .prediction-market get-current-odds u1 true)
;; Returns: (ok u143) ;; 1.43x for YES

(contract-call? .prediction-market get-current-odds u1 false)
;; Returns: (ok u333) ;; 3.33x for NO
```

**5. Resolution Time - Oracle Resolves**
```clarity
;; After resolution deadline, outcome is YES
(contract-call? .prediction-market resolve-market u1 true)
;; Returns: (ok true)
;; Oracle reputation: 105
```

**6. Winners Claim Payouts**
```clarity
;; Trader A claims (bet 500 YES, YES won)
(contract-call? .prediction-market claim-winnings u1)
;; Returns: (ok u714285714) ;; ~714 STX
;; Calculation: (500 × 1000) / 700 = 714.29 STX

;; Trader C claims (bet 200 YES, YES won)
(contract-call? .prediction-market claim-winnings u3)
;; Returns: (ok u285714286) ;; ~286 STX
;; Calculation: (200 × 1000) / 700 = 285.71 STX

;; Trader B claims (bet 300 NO, lost)
(contract-call? .prediction-market claim-winnings u2)
;; Returns: (ok u0) ;; Lost bet
```

### Dispute Scenario

**Challenge Oracle Resolution**
```clarity
(contract-call? .prediction-market dispute-resolution 
  u1 
  "Bitcoin did not reach $100k. Oracle resolution appears incorrect based on CoinMarketCap historical data.")
;; Returns: (ok true)
;; Oracle reputation: 105 → 95
;; Dispute count: 0 → 1
```

### Market Cancellation

**Creator Cancels Market**
```clarity
;; Before trading deadline
(contract-call? .prediction-market cancel-market u1)
;; Returns: (ok true)
;; Market marked resolved with no outcome
;; Positions can't claim (refund logic needed)
```

### Query Examples

**View Market Details**
```clarity
(contract-call? .prediction-market get-market u1)
;; Returns complete market information
```

**Check Position**
```clarity
(contract-call? .prediction-market get-position u1)
;; Returns: {
;;   market-id: u1,
;;   trader: 'SP2TRADER...,
;;   prediction: true,
;;   amount: u500000000,
;;   odds-at-entry: u143,
;;   claimed: true,
;;   created-at: u1000
;; }
```

**Trader Performance**
```clarity
(contract-call? .prediction-market get-trader-stats 'SP2TRADER...)
;; Returns: {
;;   total-wagered: u500000000,
;;   total-won: u714285714,
;;   markets-traded: u1,
;;   win-rate: u100
;; }
```

**Oracle Reputation**
```clarity
(contract-call? .prediction-market get-oracle-profile 'SP2ORACLE...)
;; Returns: {
;;   name: "TrustedSports Oracle",
;;   reputation: u95,
;;   markets-resolved: u1,
;;   disputes: u1,
;;   active: true
;; }
```

## Market Categories

### Common Categories

**Politics**
- Elections
- Policy outcomes
- Approval ratings
- Legislative votes

**Sports**
- Game outcomes
- Championship winners
- Player statistics
- Transfers/trades

**Cryptocurrency**
- Price predictions
- Technology adoption
- Protocol upgrades
- Regulatory decisions

**Technology**
- Product launches
- Company milestones
- AI breakthroughs
- Adoption rates

**Finance**
- Stock prices
- Economic indicators
- Interest rates
- Corporate earnings

**Entertainment**
- Award show winners
- Box office performance
- Streaming metrics
- Celebrity events

**Science**
- Research breakthroughs
- Climate events
- Space missions
- Medical approvals

## Odds & Probability

### Implied Probability
```
YES Probability = YES Pool / Total Pool
NO Probability = NO Pool / Total Pool

Example:
YES: 700 / 1000 = 70%
NO: 300 / 1000 = 30%
```

### Return on Investment
```
ROI = (Payout - Bet) / Bet × 100%

Example (YES wins):
Bet: 500 STX
Payout: 714 STX
ROI: (714 - 500) / 500 × 100 = 42.8%
```

### Expected Value
```
EV = (Win Probability × Payout) - (Loss Probability × Bet)

Example:
If you believe YES has 80% chance:
EV = (0.8 × 714) - (0.2 × 500) = 471.2 STX
Positive EV indicates profitable bet
```

## Risk Management

### For Traders
- **Research**: Verify facts before betting
- **Position Sizing**: Don't bet more than you can afford to lose
- **Diversification**: Spread bets across multiple markets
- **Odds Analysis**: Compare implied probability to your belief
- **Oracle Reputation**: Check oracle history before betting
- **Early Betting**: Better odds when pools are small
- **Late Betting**: More information but worse odds

### For Market Creators
- **Clear Questions**: Unambiguous yes/no questions
- **Objective Criteria**: Verifiable resolution criteria
- **Trusted Oracles**: Select reliable resolvers
- **Appropriate Deadlines**: Sufficient time for trading and resolution
- **Category Selection**: Proper classification for discovery

### For Oracles
- **Objective Resolution**: Follow clear criteria
- **Timely Resolution**: Resolve promptly after deadline
- **Documentation**: Keep evidence of resolution source
- **Dispute Management**: Respond to legitimate challenges
- **Reputation Protection**: Maintain high accuracy rate

## Use Cases

### Information Markets
Aggregate crowd wisdom to predict future events more accurately than expert polls or individual forecasts.

### Hedging
Traders hedge against unfavorable outcomes in their business or personal life by betting on those outcomes.

### Entertainment
Sports fans and enthusiasts bet on games and events for entertainment value.

### Research
Academics study prediction market accuracy and information aggregation mechanisms.

### Forecasting
Organizations use prediction markets internally for strategic planning and risk assessment.

## Integration Guide

### Frontend Integration

**Create Market Flow**
```javascript
import { openContractCall, stringAsciiCV, uintCV, principalCV } from '@stacks/connect';

async function createMarket(question, description, category, resDeadline, tradeDuration, oracle) {
  return await openContractCall({
    contractAddress: 'SP2...',
    contractName: 'prediction-market',
    functionName: 'create-market',
    functionArgs: [
      stringAsciiCV(question),
      stringAsciiCV(description),
      stringAsciiCV(category),
      uintCV(resDeadline),
      uintCV(tradeDuration),
      principalCV(oracle)
    ],
  });
}
```

**Place Bet**
```javascript
async function placeBet(marketId, prediction, amount) {
  return await openContractCall({
    contractAddress: 'SP2...',
    contractName: 'prediction-market',
    functionName: 'place-bet',
    functionArgs: [
      uintCV(marketId),
      boolCV(prediction),
      uintCV(amount)
    ],
  });
}
```

**Query Odds**
```javascript
import { callReadOnlyFunction, uintCV, boolCV } from '@stacks/transactions';

async function getCurrentOdds(marketId, prediction) {
  return await callReadOnlyFunction({
    contractAddress: 'SP2...',
    contractName: 'prediction-market',
    functionName: 'get-current-odds',
    functionArgs: [uintCV(marketId), boolCV(prediction)],
  });
}
```

### Backend Services

**Market Monitor**
- Track trading deadlines
- Alert when resolution time approaches
- Notify users of market resolutions
- Calculate win rates and statistics

**Odds Calculator**
- Real-time odds updates
- Historical odds tracking
- Arbitrage opportunity detection
- Expected value calculations

**Oracle Service**
- Automated resolution where possible
- API integrations for data sources
- Multi-signature resolution for disputes
- Reputation tracking and alerts

**Analytics Dashboard**
- Market volume tracking
- Category performance
- Top traders leaderboard
- Oracle reliability metrics

## Best Practices

### Creating Good Markets
1. **Clear Binary Question**: Must be answerable YES or NO
2. **Specific Criteria**: Define exactly what constitutes YES
3. **Verifiable Outcome**: Must be objectively determinable
4. **Reasonable Timeline**: Not too short or too long
5. **Public Information**: Resolution source should be public
6. **Relevant Category**: Help users find your market

### Good Market Examples
✅ "Will the S&P 500 close above 5000 on Dec 31, 2024?"
✅ "Will Team A win the championship game on [date]?"
✅ "Will candidate win election with >50% of vote?"

### Bad Market Examples
❌ "Will AI become sentient?" (Too subjective)
❌ "Will I be happy next year?" (Not verifiable)
❌ "Will price go up?" (Not specific enough)

### Trading Strategies

**Value Betting**
- Bet when your probability estimate differs significantly from market odds
- Example: Market says 30% chance, you believe 50%

**Arbitrage**
- Exploit odds discrepancies across markets
- Requires careful position sizing

**Early Bird**
- Bet early when pools are small for better odds
- Higher risk as information emerges

**Late Information**
- Wait for more information before betting
- Worse odds but better informed decisions

## Technical Specifications

- **Question Length**: 256 characters max
- **Description Length**: 512 characters max
- **Category**: 32 characters
- **Dispute Reason**: 256 characters max
- **Oracle Name**: 64 characters
- **Position Limit**: 20 per trader per market
- **Odds Precision**: Whole numbers (100 = 1.00x)
- **Deadline Units**: Block height (~10 min per block)

## Known Limitations

1. **Binary Only**: No multi-outcome or scalar markets
2. **No Partial Claims**: Must claim entire position at once
3. **No Refunds**: Cancelled markets don't auto-refund
4. **Oracle Trust**: Relies on oracle honesty
5. **Simple Dispute**: Dispute filing doesn't trigger resolution review
6. **No Liquidity Provision**: All liquidity from bettors
7. **Fixed Pools**: Can't remove liquidity before resolution

## Security Considerations

### Implemented Security
- Oracle-only resolution authority
- Trader-only winnings claims
- Trading deadline enforcement
- Resolution deadline enforcement
- Amount validation (> 0)
- Double-claim prevention
- Oracle registration requirement

### Recommendations
1. Implement multi-sig oracle resolution for high-value markets
2. Add time-lock for large payouts
3. Create dispute resolution DAO
4. Add market maker incentives
5. Implement maximum bet limits
6. Add cooling-off period for new markets
7. Create insurance fund for disputed resolutions

## Development & Testing

### Prerequisites
- Clarinet CLI installed
- Understanding of prediction market mechanics
- STX testnet tokens

### Local Testing
```bash
# Validate contract
clarinet check

# Run tests
clarinet test

# Interactive console
clarinet console
```

### Deployment
```bash
# Testnet
clarinet deploy --testnet

# Mainnet
clarinet deploy --mainnet
```

## Roadmap

**Phase 1** (Current)
- Binary prediction markets
- Oracle resolution
- Dynamic odds
- Dispute mechanism

**Phase 2** (Planned)
- Multi-outcome markets
- Scalar markets (price ranges)
- Automated market makers
- Partial position closing
- Enhanced dispute resolution

**Phase 3** (Future)
- Cross-chain oracle integration (Chainlink)
- NFT positions (tradeable bets)
- Market derivatives
- DAO governance
- AI-powered market suggestions
- Liquidity mining rewards

## Contributing

Contributions welcome! Priority areas:
- Multi-outcome market support
- Automated market maker
- Enhanced dispute resolution
- Oracle reputation enhancements
- UI/UX improvements

## License

MIT License - Open source and free to use

## Support

- **Documentation**: This README
- **Contract**: View on Stacks Explorer
- **Issues**: GitHub Issues
- **Community**: Discord/Telegram

---

**Disclaimer**: Prediction markets involve financial risk and may not be legal in all jurisdictions. Users should understand the risks of betting and comply with local regulations. The platform is not responsible for losses, disputed resolutions, or regulatory consequences. Oracle resolution is final and binding per the smart contract terms. Always bet responsibly and only what you can afford to lose.
