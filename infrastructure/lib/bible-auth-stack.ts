import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

export interface BibleAuthStackProps extends cdk.StackProps {
  // Optional: Add custom props here if needed
}

export class BibleAuthStack extends cdk.Stack {
  public readonly userPool: cognito.UserPool;
  public readonly userPoolClient: cognito.UserPoolClient;
  public readonly userPoolDomain: cognito.UserPoolDomain;

  constructor(scope: Construct, id: string, props?: BibleAuthStackProps) {
    super(scope, id, props);

    // =============================================================
    // COGNITO USER POOL
    // =============================================================
    this.userPool = new cognito.UserPool(this, 'BibleAppUserPool', {
      userPoolName: 'bible-app-user-pool',
      
      // Self sign-up enabled
      selfSignUpEnabled: true,
      
      // Sign-in options
      signInAliases: {
        email: true,
        username: false,
      },
      
      // Email verification
      autoVerify: {
        email: true,
      },
      
      // User verification
      userVerification: {
        emailSubject: 'Verify your Bible App account',
        emailBody: 'Thanks for signing up! Your verification code is {####}',
        emailStyle: cognito.VerificationEmailStyle.CODE,
      },
      
      // Password policy
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: true,
        tempPasswordValidity: cdk.Duration.days(7),
      },
      
      // Account recovery
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      
      // Standard attributes
      standardAttributes: {
        email: {
          required: true,
          mutable: true,
        },
        givenName: {
          required: false,
          mutable: true,
        },
        familyName: {
          required: false,
          mutable: true,
        },
      },
      
      // Custom attributes
      customAttributes: {
        createdAt: new cognito.DateTimeAttribute(),
        preferredTranslation: new cognito.StringAttribute({ mutable: true }),
      },
      
      // MFA (optional - disabled for now)
      mfa: cognito.Mfa.OFF,
      
      // Keep users for auditing
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // =============================================================
    // SOCIAL IDENTITY PROVIDERS (OPTIONAL - Add later)
    // =============================================================
    // NOTE: Social identity providers (Apple, Google) are commented out
    // because they require valid OAuth credentials to be configured.
    // 
    // To enable social login later:
    // 1. Set up OAuth credentials in Apple Developer Console and Google Cloud Console
    // 2. Create secrets in AWS Secrets Manager with the credentials
    // 3. Uncomment the provider code below and redeploy
    //
    // For now, email/password authentication is enabled and ready to use.
    
    /*
    // Secret for Google OAuth credentials
    const googleSecret = new secretsmanager.Secret(this, 'GoogleOAuthSecret', {
      secretName: 'bible-app/google-oauth',
      description: 'Google OAuth credentials for Bible App',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          clientId: 'YOUR_GOOGLE_CLIENT_ID',
        }),
        generateStringKey: 'clientSecret',
      },
    });

    // Secret for Apple OAuth credentials
    const appleSecret = new secretsmanager.Secret(this, 'AppleOAuthSecret', {
      secretName: 'bible-app/apple-oauth',
      description: 'Apple OAuth credentials for Bible App',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          clientId: 'YOUR_APPLE_SERVICE_ID',
          teamId: 'YOUR_APPLE_TEAM_ID',
          keyId: 'YOUR_APPLE_KEY_ID',
        }),
        generateStringKey: 'privateKey',
      },
    });

    // Google Identity Provider
    const googleProvider = new cognito.UserPoolIdentityProviderGoogle(this, 'GoogleProvider', {
      userPool: this.userPool,
      clientId: googleSecret.secretValueFromJson('clientId').unsafeUnwrap(),
      clientSecretValue: googleSecret.secretValueFromJson('clientSecret'),
      scopes: ['profile', 'email', 'openid'],
      attributeMapping: {
        email: cognito.ProviderAttribute.GOOGLE_EMAIL,
        givenName: cognito.ProviderAttribute.GOOGLE_GIVEN_NAME,
        familyName: cognito.ProviderAttribute.GOOGLE_FAMILY_NAME,
        profilePicture: cognito.ProviderAttribute.GOOGLE_PICTURE,
      },
    });

    // Apple Identity Provider
    const appleProvider = new cognito.UserPoolIdentityProviderApple(this, 'AppleProvider', {
      userPool: this.userPool,
      clientId: appleSecret.secretValueFromJson('clientId').unsafeUnwrap(),
      teamId: appleSecret.secretValueFromJson('teamId').unsafeUnwrap(),
      keyId: appleSecret.secretValueFromJson('keyId').unsafeUnwrap(),
      privateKeyValue: appleSecret.secretValueFromJson('privateKey'),
      scopes: ['email', 'name'],
      attributeMapping: {
        email: cognito.ProviderAttribute.APPLE_EMAIL,
        givenName: cognito.ProviderAttribute.APPLE_FIRST_NAME,
        familyName: cognito.ProviderAttribute.APPLE_LAST_NAME,
      },
    });
    */

    // =============================================================
    // USER POOL DOMAIN (for hosted UI and OAuth)
    // =============================================================
    this.userPoolDomain = this.userPool.addDomain('CognitoDomain', {
      cognitoDomain: {
        // This creates a domain like: bible-app-auth-186509.auth.us-east-1.amazoncognito.com
        // Using a fixed prefix with partial account ID for uniqueness
        domainPrefix: 'bible-app-auth-186509',
      },
    });

    // =============================================================
    // USER POOL CLIENT (for iOS app)
    // =============================================================
    this.userPoolClient = this.userPool.addClient('BibleAppClient', {
      userPoolClientName: 'bible-app-ios-client',
      
      // Generate a client secret (needed for some OAuth flows)
      generateSecret: false,
      
      // Auth flows
      authFlows: {
        userPassword: true,
        userSrp: true,
        custom: true,
      },
      
      // OAuth configuration
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
          implicitCodeGrant: false,
        },
        scopes: [
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE,
        ],
        // Callback URLs for OAuth (update with your app's URL scheme)
        callbackUrls: [
          'biblev1://callback',
          'https://localhost:3000/callback', // For testing
        ],
        logoutUrls: [
          'biblev1://signout',
          'https://localhost:3000/signout', // For testing
        ],
      },
      
      // Token validity
      accessTokenValidity: cdk.Duration.hours(1),
      idTokenValidity: cdk.Duration.hours(1),
      refreshTokenValidity: cdk.Duration.days(30),
      
      // Enable token revocation
      enableTokenRevocation: true,
      
      // Prevent user existence errors
      preventUserExistenceErrors: true,
      
      // Supported identity providers
      // NOTE: Only Cognito (email/password) is enabled for now
      // Add GOOGLE and APPLE after configuring OAuth credentials
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO,
        // cognito.UserPoolClientIdentityProvider.GOOGLE,
        // cognito.UserPoolClientIdentityProvider.APPLE,
      ],
    });

    // When social providers are enabled, add dependencies:
    // this.userPoolClient.node.addDependency(googleProvider);
    // this.userPoolClient.node.addDependency(appleProvider);

    // =============================================================
    // OUTPUTS (for iOS app configuration)
    // =============================================================
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: this.userPool.userPoolId,
      description: 'Cognito User Pool ID',
      exportName: 'BibleAppUserPoolId',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: this.userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID',
      exportName: 'BibleAppUserPoolClientId',
    });

    new cdk.CfnOutput(this, 'UserPoolDomain', {
      value: this.userPoolDomain.domainName,
      description: 'Cognito User Pool Domain',
      exportName: 'BibleAppUserPoolDomain',
    });

    new cdk.CfnOutput(this, 'Region', {
      value: this.region,
      description: 'AWS Region',
      exportName: 'BibleAppRegion',
    });

    // Outputs for social provider secrets (when enabled):
    // new cdk.CfnOutput(this, 'GoogleSecretArn', {
    //   value: googleSecret.secretArn,
    //   description: 'ARN of the Google OAuth secret',
    // });
    // new cdk.CfnOutput(this, 'AppleSecretArn', {
    //   value: appleSecret.secretArn,
    //   description: 'ARN of the Apple OAuth secret',
    // });
  }
}

