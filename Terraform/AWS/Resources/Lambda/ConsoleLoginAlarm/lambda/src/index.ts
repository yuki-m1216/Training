import { EventBridgeEvent } from "aws-lambda";
import { ConsoleLoginDetailModel, UserIdentity } from "./models/models";

export const handler = async (
  event: EventBridgeEvent<
    "AWS Console Sign In via CloudTrail",
    ConsoleLoginDetailModel
  >
): Promise<void> => {
  const detail = event.detail;
  console.log(`Received event: ${JSON.stringify(detail)}`);
  // detail.eventName === "ConsoleLogin" is necessary
  if (detail.eventName !== "ConsoleLogin") {
    return;
  }
  const url = `https://${process.env.webhookURL as string}`;
  const consoleLoginResult = detail.responseElements.ConsoleLogin;
  const user = getUser(detail.userIdentity);
  const message = `Console login ${consoleLoginResult} for account ${user} from ${detail.sourceIPAddress} at ${detail.eventTime}.`;
  const sendData = {
    blocks: [
      {
        type: "section",
        text: {
          text: message,
          type: "mrkdwn",
        },
      },
    ],
  };
  const apifech = await fetch(url, {
    method: "POST",
    body: JSON.stringify(sendData),
    headers: {
      "Content-Type": "application/json",
    },
  });
  console.log(apifech);
  return;
};

const getUser = (userIdentity: UserIdentity): string => {
  switch (userIdentity.type) {
    case "IAMUser":
      return userIdentity.userName;
    case "AssumedRole":
      return userIdentity.sessionContext!.sessionIssuer.userName;
    case "Root":
      return userIdentity.type;
    default:
      return JSON.stringify(userIdentity);
  }
};
