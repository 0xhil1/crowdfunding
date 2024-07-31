export const Contracts = {
  crowdfund: "0x27841cd89E9996c6AD39D3f772fE637F4C7A4622",
};

export enum FundingState {
  NOT_INITIALIZED,
  NOT_STARTED, // funding goal not set yet
  IN_PROGRESS, // in progress
  FULLY_FUNDED, // funding goal met
  DEADLINE_PASSED, // funding goal not met and deadline limited
}
