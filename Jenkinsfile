#!groovy
readProperties = loadConfigurationFile 'configFile'

pipeline {
  agent {
    docker {
      image readProperties.imagePipeline
      args '-v tf_plugins:/plugins'
    }
  }
  environment {
    AWS_ACCESS_KEY_ID = credentials('aws_access_key')
    AWS_SECRET_ACCESS_KEY = credentials('aws_secret_key')
    TF_VAR_my_public_key_path = credentials('ssh-public-key')
    TF_VAR_my_private_key_path = credentials('ssh-private-key')
  }
  triggers {
       pollSCM('H/5 * * * *')
  }
  stages {
    stage('validate') {
      when { 
        expression{ env.BRANCH_NAME ==~ /dev.*/ || 
            env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ }
      }
      steps {
        verifyInfra 'examples/global', '.'
        verifyInfra 'examples/chef_server', '.'

      }
    }
    stage('Compute Changes') {
      when { 
        expression{ env.BRANCH_NAME ==~ /dev.*/ || 
          env.BRANCH_NAME ==~ /PR.*/ }
      }
      steps {
        computeInfra 'examples/global', '.'
        computeInfra 'examples/chef_server', '.'
        input(message: "Do you want to apply those plans?", ok: "yes")
        applyChangesInfra 'examples/global', '.'
        applyChangesInfra 'examples/chef_server', '.'
      }
    }
    stage('destroy') {
      when { 
        expression{ env.BRANCH_NAME ==~ /dev.*/ || 
          env.BRANCH_NAME ==~ /PR.*/ }
      }
      steps {
        input(message: "Do you want to destroy everything?", ok: "yes")
        destroyInfra 'examples/global', '.'
        destroyInfra 'examples/chef_server', '.'
      }
    }
  }
}