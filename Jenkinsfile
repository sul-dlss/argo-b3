def secrets = [
    [path: 'application/argo-b3/honeybadger-api-key', secretValues: [
        [envVar: 'HONEYBADGER_API_KEY', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/secret-key-base', secretValues: [
        [envVar: 'SECRET_KEY_BASE', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/dor-services-token', secretValues: [
        [envVar: 'SETTINGS__DOR_SERVICES__TOKEN', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/preservation-catalog-token', secretValues: [
        [envVar: 'SETTINGS__PRESERVATION_CATALOG__TOKEN', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/lyberadmin-db-pwd', secretValues: [
        [envVar: 'DATABASE_PASSWORD', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/rabbitmq-username', secretValues: [
        [envVar: 'SETTINGS__RABBITMQ__USERNAME', vaultKey: 'content']]],
    [path: 'application/argo-b3/stage/rabbitmq-password', secretValues: [
        [envVar: 'SETTINGS__RABBITMQ__PASSWORD', vaultKey: 'content']]],
    [path: 'application/folio/app_sdr_password', secretValues: [
        [envVar: 'SETTINGS__FOLIO__OKAPI__PASSWORD', vaultKey: 'content']]]
]

pipeline {
  agent any

  environment {
    PROJECT = 'sul-dlss/argo-b3'
    // Without explicit UTF-8, the Psych YAML library will run into encoding
    // mismatches and the build will explode.
    LANG = 'C.UTF-8'
    LC_ALL = 'C.UTF-8'
  }

  stages {
    stage('Deploy to stage on merges to main') {
      environment {
        DEPLOY_ENVIRONMENT = 'stage'
      }

      when {
        branch 'main'
      }

      steps {
        checkout scm

        withVault([vaultSecrets: secrets]) {
          sshagent (['sul-devops-team', 'sul-continuous-deployment']) {
            sh '''#!/bin/bash -l
              # Load application dependencies
              rvm use 3.4.1@argo-b3 --create
              gem install bundler
              bundle install

              # Deploy it
              bundle exec bin/kamal deploy -d $DEPLOY_ENVIRONMENT
            '''
          }
        }
      }

      post {
        always {
          build job: '/Continuous Deployment/Slack Deployment Notification', parameters: [
            string(name: 'PROJECT', value: env.PROJECT),
            string(name: 'GIT_COMMIT', value: env.GIT_COMMIT),
            string(name: 'GIT_URL', value: env.GIT_URL),
            string(name: 'GIT_PREVIOUS_SUCCESSFUL_COMMIT', value: env.GIT_PREVIOUS_SUCCESSFUL_COMMIT),
            string(name: 'DEPLOY_ENVIRONMENT', value: env.DEPLOY_ENVIRONMENT),
            string(name: 'TAG_NAME', value: env.TAG_NAME),
            booleanParam(name: 'SUCCESS', value: currentBuild.resultIsBetterOrEqualTo('SUCCESS')),
            string(name: 'RUN_DISPLAY_URL', value: env.RUN_DISPLAY_URL)
          ]
        }
      }
    }
  }
}
