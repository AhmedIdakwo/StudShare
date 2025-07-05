# StudShare

**StudShare** is a Clarity smart contract that enables fractional ownership, race strategy governance, and prize distribution for thoroughbred racehorses. It allows multiple investors to co-own racehorses, participate in voting on race strategies, and claim their share of race winnings — all in a decentralized and transparent way.

---

## ✨ Features

- **Horse Registration**: Register new racehorses with details such as name, share supply, trainer, and racing status.
- **Fractional Ownership**: Users can buy shares in a registered horse, enabling collective ownership.
- **Prize Distribution**: Trainers can initiate prize distribution after races, and owners can claim their share based on holdings.
- **Race Governance**: Shareholders can propose and vote on racing strategies for upcoming races.
- **Secure Voting**: One-vote-per-owner per race decision with share-weighted impact.
- **Read-only Access**: Easily query horse info, share balances, race proposals, and potential winnings.

---

## 📜 Contract Structure

### Constants

- `STABLE_MASTER`: Only the stable master (contract deployer) can register horses.
- Custom errors for authorization, invalid input, and race conditions.

### Data Structures

- **`thoroughbreds`**: Metadata and status for each registered horse.
- **`owner-shares`**: Mapping of horse share ownership per principal.
- **`race-decisions`**: Voting proposals for horse race strategies.
- **`race-votes`**: Tracks which owners have voted and how.
- **`prize-claims`**: Prevents double-claiming of race winnings.

---

## 📦 Public Functions

### 🐎 Horse Management
- `register-horse(name, total-shares, share-cost, race-earnings, trainer)`
- `buy-shares(horse-id, share-amount)`

### 💰 Winnings
- `distribute-winnings(horse-id, season)`
- `claim-winnings(horse-id, season)`

### 🗳️ Race Governance
- `create-race-decision(horse-id, race-name, strategy, voting-period)`
- `vote-race(race-id, agrees)`

---

## 🔍 Read-Only Functions

- `get-horse(horse-id)`
- `get-share-balance(horse-id, owner)`
- `get-race-decision(race-id)`
- `calculate-winning-share(horse-id, owner)`

---

## 🔐 Access Control

- Only the **stable master** can register horses.
- Only the **horse trainer** can distribute winnings.
- Only **shareholders** can vote on race decisions or propose them.
