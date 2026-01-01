#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { BibleAuthStack } from '../lib/bible-auth-stack';

const app = new cdk.App();

// Get environment from context or use defaults
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT || app.node.tryGetContext('account'),
  region: process.env.CDK_DEFAULT_REGION || app.node.tryGetContext('region') || 'us-east-1',
};

new BibleAuthStack(app, 'BibleAuthStack', {
  env,
  description: 'Bible App Authentication Infrastructure with Cognito',
  
  // Stack-level tags
  tags: {
    Project: 'BibleApp',
    Environment: 'Production',
    ManagedBy: 'CDK',
  },
});

app.synth();

