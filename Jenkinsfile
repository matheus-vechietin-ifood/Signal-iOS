pipeline {
  agent any
  stages {
    stage('Trigger Bitrise') {
      steps {
        sh 'curl -X POST -H "Authorization: cWYAFthA_XT-2ZEkUlUr-5D5JULuHkGbGvb-V0eKd5Kfkm_W8uW-k1nFp7LwDVygWtOI2A5el1SyM2WUdP61hA" "https://api.bitrise.io/v0.1/apps/8367a773e7be4f36/builds" -d \'{"hook_info":{"type":"bitrise"},"build_params":{"branch":"release/2.40.1"}}\' | jq'
      }
    }
  }
}