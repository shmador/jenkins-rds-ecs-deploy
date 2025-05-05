pipeline {
	agent any
	stages {
		stage('Create and push docker image to ecr') {
			steps {
				withCredentials([[
				    $class: 'AmazonWebServicesCredentialsBinding',
				    credentialsId: '05e6adcb-0128-4101-bca4-350064a1de3d',
				    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
				    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
				]]) {
					sh '''
					aws ecr get-login-password --region il-central-1 | docker login --username AWS --password-stdin 314525640319.dkr.ecr.il-central-1.amazonaws.com
					docker build -t dor/nginx:${BUILD_NUMBER} .
					docker tag dor/nginx:${BUILD_NUMBER} 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest
					docker push 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest
					echo "ECR_URL=314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest"	> .env
					export $(cat .env | xargs)
					export TF_VAR_image=$ECR_URL
					terraform destroy -auto-approve
					terraform init
					terraform apply -auto-approve
					'''
				}
			}
		}
	}

}
