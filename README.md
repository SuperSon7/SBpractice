# Spring Boot 무중단 CI/CD 파이프라인 구축 프로젝트

## 📖 프로젝트 개요 (Overview)

이 프로젝트는 기존에 개발된 Spring Boot 기반의 웹 애플리케이션을 AWS 클라우드 환경에 안정적으로 자동 배포하기 위한 CI/CD 파이프라인을 구축하는 것을 목표로 합니다.

단순히 서비스를 배포하는 것을 넘어, 컨테이너화, Infrastructure as Code(IaC), 안전한 인증 방식(OIDC), 자동화된 원격 배포 등 현대적인 DevOps 모범 사례(Best Practice)를 적용하여 보안과 유지보수성이 높고 확장 가능한 아키텍처를 설계하고 구현합니다.

## 🏗️ 목표 아키텍처 (Target Architecture)

### 작동 흐름

1. **Code & Push:** 개발자가 로컬에서 코드를 수정한 후 GitHub의 `master` 브랜치로 Push 또는 Merge 합니다.

2. **CI (Continuous Integration):** `GitHub Actions`가 이를 감지하고 워크플로우를 실행합니다.
   - 코드를 테스트하고 Gradle로 빌드하여 `.jar` 파일을 생성합니다.
   - `Dockerfile`을 이용해 애플리케이션을 Docker 이미지로 패키징합니다.

3. **Store Artifact:** 빌드된 Docker 이미지를 버전 태그와 함께 **AWS ECR (Elastic Container Registry)**에 업로드하여 영구 저장합니다. 이 과정은 **OIDC**를 통해 임시 자격 증명으로 안전하게 수행됩니다.

4. **CD (Continuous Deployment):** 이미지가 ECR에 성공적으로 업로드되면, GitHub Actions가 **AWS SSM (Systems Manager) Run Command**를 통해 EC2 인스턴스에 원격으로 배포 명령을 전달하여 무중단으로 서비스를 업데이트합니다.

5. **IaC (Infrastructure as Code):** 위의 모든 AWS 인프라(VPC, EC2, Security Group, IAM 역할 등)는 AWS 콘솔에서 수동으로 생성하는 것이 아니라, **Terraform 코드**를 통해 선언적으로 정의되고 관리됩니다.

## ✨ 주요 특징 (Key Features)

- **완전 자동화된 CI/CD 파이프라인** (GitHub Actions)
- **컨테이너 기반의 애플리케이션 환경** (Docker)
- **코드로 관리되는 인프라** (Terraform, IaC)
- **안전한 이미지 저장 및 관리** (AWS ECR)
- **액세스 키 없는 안전한 클라우드 인증** (AWS IAM OIDC 연동)
- **SSH 포트 노출 없는 안전한 원격 배포** (AWS SSM Run Command)
- **최소 권한 원칙을 준수하는 역할 분리** (IAM Roles for Terraform, ECR, SSM)
- **민감 정보의 안전한 관리** (환경 변수, `.env`, GitHub Secrets)

## 🛠️ 기술 스택 (Tech Stack)

- **Application:** Java 21, Spring Boot 3.x, Spring Security, JPA, Gradle
- **Database:** PostgreSQL
- **CI/CD & Automation:** GitHub Actions, Docker, Docker Compose
- **Cloud (AWS):** EC2, ECR, VPC, IAM, **SSM (Systems Manager)**
- **IaC:** Terraform

## 📋 프로젝트 진행 기록 (Journey)

### Phase 1: 로컬 개발 환경 현대화

- ✅ H2 인메모리 DB를 프로덕션급인 **PostgreSQL**로 마이그레이션
- ✅ Docker를 이용해 로컬 환경에 PostgreSQL 서버를 컨테이너로 실행
- ✅ **환경 변수**를 도입하여 DB 및 OAuth 등 민감 정보를 코드와 분리
- ✅ '실행 환경'과 '테스트 환경'의 차이를 이해하고, 별도 설정을 추가하여 **테스트 빌드 성공**

### Phase 2: 애플리케이션 패키징 및 실행

- ✅ 프로덕션용 JRE 이미지를 사용하는 **멀티 스테이지** `Dockerfile` 작성
- ✅ 애플리케이션과 데이터베이스를 하나의 세트로 관리하기 위한 `docker-compose.yml` 파일 작성 완료
- ✅ `docker-compose up` 명령어로 로컬 환경에서 전체 서비스가 동작하는 것을 확인

### Phase 3: CI 파이프라인 구축 및 보안 강화

- ✅ GitHub Actions 워크플로우 (`ci.yml`) 초안 작성 및 실행
- ✅ **AWS IAM User Access Key**를 사용하는 초기 CI 파이프라인 완성 (빌드 및 ECR 푸시)
- ✅ **보안 강화:** 영구적인 Access Key 방식의 취약점을 해결하기 위해, **AWS IAM OIDC 자격 증명 공급자**를 도입
- ✅ **최소 권한 원칙 적용:** Terraform, ECR Push, SSM 실행 등 각 작업에 필요한 최소한의 권한만 가진 **IAM 역할을 분리**하여 생성
- ✅ 이제 파이프라인은 더 이상 Access Key를 사용하지 않고, 각 작업마다 필요한 임시 자격 증명을 발급받아 안전하게 실행됨

### Phase 4: 인프라 자동화 및 배포 방식 현대화 (IaC & CD)

- ✅ **Terraform**을 도입하여 VPC, Subnet, Internet Gateway, Security Group 등 모든 네트워크 인프라를 **코드로 정의하고 관리**
- ✅ EC2 인스턴스 및 인스턴스에 연결될 IAM 역할(SSM, ECR Pull 권한) 또한 Terraform으로 자동 생성
- ✅ **배포 방식 개선:** 기존의 SSH 접속 방식(`appleboy/ssh-action`)을 제거
- ✅ **AWS SSM Run Command**를 도입하여 SSH 포트를 외부에 노출하지 않고 원격으로 EC2에 배포 스크립트를 실행하는 **안전한 CD 파이프라인 완성**
- ✅ `git push` 한 번으로 코드 수정부터 인프라 변경, 애플리케이션 배포까지 모든 과정이 자동으로 처리되는 기반 마련

---

> **참고:** 이 프로젝트는 DevOps 모범 사례를 학습하고 적용하기 위한 목적으로 진행되었으며, 각 단계별로 점진적인 개선과 보안 강화를 통해 현대적인 클라우드 네이티브 애플리케이션 배포 환경을 구축하였습니다.