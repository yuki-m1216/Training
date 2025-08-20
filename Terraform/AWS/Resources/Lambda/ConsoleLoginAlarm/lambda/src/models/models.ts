export interface ConsoleLoginDetailModel {
  eventVersion: string;
  userIdentity: UserIdentity;
  eventTime: Date;
  eventSource: string;
  eventName: string;
  awsRegion: string;
  sourceIPAddress: string;
  userAgent: string;
  requestParameters: null;
  responseElements: ResponseElements;
  additionalEventData: AdditionalEventData;
  eventID: string;
  readOnly: boolean;
  eventType: string;
  managementEvent: boolean;
  recipientAccountId: string;
  eventCategory: string;
  tlsDetails: TLSDetails;
}

export interface UserIdentity {
  type: string;
  principalId: string;
  arn: string;
  accountId?: string;
  accessKeyId?: string;
  userName: string;
  sessionContext?: SsessionContext;
}

export interface SsessionContext {
  sessionIssuer: SessionIssuer;
  attributes: Attributes;
}

export interface SessionIssuer {
  type: string;
  principalId: string;
  arn: string;
  accountId: string;
  userName: string;
}

export interface Attributes {
  mfaAuthenticated: string;
  creationDate: string;
}

export interface ResponseElements {
  ConsoleLogin: string;
}

export interface AdditionalEventData {
  LoginTo?: string;
  MobileVersion?: string;
  MFAUsed?: string;
  MfaType?:string;
  MFAIdentifier?: string;
}

export interface TLSDetails {
  tlsVersion: string;
  cipherSuite: string;
  clientProvidedHostHeader: string;
}
