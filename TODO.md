# TODO

## Firebase Migration (Real-time & Secure)

### Step 1: Fix Admin results screen
- [x] Remove any non-existent `_resultsData` references (print button)
- [x] Ensure loading spinner stops for election/tickets empty & permission error

- [x] Ensure real-time charts use Firestore streams only (no timers)


### Step 2: Migrate ResultsScreen (voter)
- [x] Remove ApiService + Timer polling

- [ ] Implement Firestore StreamBuilders for active election + tickets
- [ ] Add clean empty state: “Hakuna matokeo kwa sasa”
- [ ] Add clean permission/error message

### Step 3: Migrate VotingScreen vote casting
- [ ] Remove ApiService.castVote
- [x] Implement Firestore runTransaction

- [ ] Prevent double-vote using doc key `${'{'}electionId{'}'}_${'{'}uid{'}'}`
- [ ] Ensure atomic update of vote count
- [x] Stop spinner on all outcomes (success/already voted/permission error)


### Step 4: Analyze
- [ ] Run `flutter analyze` and ensure app files are clean


