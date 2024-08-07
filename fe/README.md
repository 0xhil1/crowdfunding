## Simple CrowdFunding UI

Frontend for CrowdFunding

### Built With

- [React](https://react.dev/)
- [Next.js](https://nextjs.org/)
- [Typescript](https://www.typescriptlang.org/)
- [RainbowKit](https://www.rainbowkit.com/)
- [TailwindCSS](https://tailwindcss.com/)

## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

- [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Install Node v18](https://heynode.com/tutorial/install-nodejs-locally-nvm)

### Installation

- Clone this repository and naviate to the folder
- Install `node_modules` by running

```bash
npm install
// or
yarn install
```

### Configuration

- Create `.env` file, You can rename the file called `.env.example` to `.env`
- Create WalletConnect Cloud project and update `NEXT_PUBLIC_RAINBOW_PROJECT_ID` in `.env` file with your own value
  [How to get WalletConnect api key](https://docs.walletconnect.com/walletkit/web/cloud/relay#project-id)

### Finally run the app

- Once you have successfully completed the steps mentioned above, you can start the application by executing the following command:

```bash
npm run dev
// or
yarn dev
```

### Build and deploy

- You can build the project by running following command:

```bash
npm run build
// or
yarn build
```

- [Deployed vercel link](https://crowdfunding-alpha-one.vercel.app/)
