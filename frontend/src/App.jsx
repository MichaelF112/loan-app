// import React, { useState } from "react";
import LoanForm from "./components/LoanForm";
import { STACKS_TESTNET } from "@stacks/network";
// import {
//   callReadOnlyFunction,
// } from "@stacks/transactions";
import {
  makeContractCall,
  uintCV,
  // cvToJSON,
  broadcastTransaction,
} from "@stacks/transactions";



const CONTRACT_ADDRESS =
  "ST2NSQSBAR746ZA5JRW8HVREGV3A9C1Q958P3BPPD";
const CONTRACT_NAME = "loan-app";

const App = () => {
  // const [loanDetails, setLoanDetails] = useState(null);

  // Utility function for contract calls
  const contractCall = async (
    functionName,
    functionArgs
  ) => {
    try {
      const options = {
        contractAddress: CONTRACT_ADDRESS,
        contractName: CONTRACT_NAME,
        functionName,
        functionArgs,
        senderKey: "",
        network: STACKS_TESTNET,
      };
      const transaction = await makeContractCall(options);
      const response = await broadcastTransaction(
        transaction,
        network
      );
      console.log("Transaction response:", response);
      alert(`Transaction successful: ${response}`);
    } catch (error) {
      console.error("Error:", error);
      alert(`Error: ${error.message}`);
    }
  };

  // // Fetch loan details
  // const fetchLoanDetails = async (loanId) => {
  //   try {
  //     const options = {
  //       contractAddress: CONTRACT_ADDRESS,
  //       contractName: CONTRACT_NAME,
  //       functionName: "get-loan-details",
  //       functionArgs: [uintCV(Number(loanId))],
  //       network,
  //       senderAddress: "YOUR_ADDRESS",
  //     };
  //     const result = await callReadOnlyFunction(options);
  //     setLoanDetails(cvToJSON(result));
  //   } catch (error) {
  //     console.error("Error fetching loan details:", error);
  //   }
  // };

  return (
    <div className="container">
      <h1>Loan Management DApp</h1>

      <h2>Create Loan</h2>
      <LoanForm
        fields={[
          {
            name: "loanId",
            label: "Loan ID",
            type: "number",
          },
          {
            name: "principal",
            label: "Principal",
            type: "number",
          },
          {
            name: "interestRate",
            label: "Interest Rate",
            type: "number",
          },
          {
            name: "dueBlock",
            label: "Due Block",
            type: "number",
          },
        ]}
        onSubmit={(values) =>
          contractCall("create-loan", [
            uintCV(Number(values.loanId)),
            uintCV(Number(values.principal)),
            uintCV(Number(values.interestRate)),
            uintCV(Number(values.dueBlock)),
          ])
        }
        buttonText="Create Loan"
      />

      {/* <h2>Fetch Loan Details</h2>
      <LoanForm
        fields={[
          {
            name: "loanId",
            label: "Loan ID",
            type: "number",
          },
        ]}
        onSubmit={(values) =>
          fetchLoanDetails(values.loanId)
        }
        buttonText="Fetch Details"
      />

      {loanDetails && (
        <div className="loan-details">
          <h3>Loan Details</h3>
          <pre>{JSON.stringify(loanDetails, null, 2)}</pre>
        </div>
      )} */}
    </div>
  );
};

export default App;
