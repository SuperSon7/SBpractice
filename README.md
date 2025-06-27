# Spring Boot Q&A 웹사이트를 위한 무중단 CI/CD 파이프라인 구축 프로젝트

## 1. 프로젝트 개요 (Overview)

이 프로젝트는 기존에 개발된 Spring Boot 기반의 질의응답(Q&A) 웹 애플리케이션을 AWS 클라우드 환경에 안정적으로 자동 배포하기 위한 CI/CD 파이프라인을 구축하는 것을 목표로 합니다.

단순히 서비스를 배포하는 것을 넘어, 컨테이너화, Infrastructure as Code(IaC), 무중단 배포 전략 등 현대적인 DevOps 모범 사례(Best Practice)를 적용하여 유지보수성이 높고 확장 가능한 아키텍처를 설계하고 구현합니다.

## 2. 목표 아키텍처 (Target Architecture)

**작동 흐름:**
1.  **Code & Push:** 개발자가 로컬에서 코드를 수정한 후 GitHub에 `git push` 합니다.
2.  **CI (Continuous Integration):** GitHub Actions가 Push를 감지하고 워크플로우를 실행합니다.
    - 코드를 테스트하고 Gradle로 빌드하여 `.jar` 파일을 생성합니다.
    - `Dockerfile`을 이용해 애플리케이션을 Docker 이미지로 만듭니다.
3.  **Store Artifact:** 빌드된 Docker 이미지를 버전 태그와 함께 **AWS ECR (Elastic Container Registry)**에 업로드하여 영구 저장합니다.
4.  **CD (Continuous Deployment):** 이미지가 ECR에 성공적으로 업로드되면, GitHub Actions가 `kubectl` 명령어를 통해 **AWS EKS (Elastic Kubernetes Service)** 클러스터에 새로운 버전의 애플리케이션을 무중단 방식으로 배포합니다.
5.  **IaC (Infrastructure as Code):** 위의 모든 AWS 인프라(VPC, ECR, EKS 등)는 AWS 콘솔에서 수동으로 생성하는 것이 아니라, **Terraform 코드**를 통해 관리되고 배포됩니다.

## 3. 주요 특징 (Key Features)

- **완전 자동화된 CI/CD 파이프라인** (GitHub Actions)
- **컨테이너 기반의 애플리케이션 환경** (Docker)
- **코드로 관리되는 인프라** (Terraform, IaC)
- **안전한 이미지 저장 및 관리** (AWS ECR)
- **고가용성 및 확장성을 위한 컨테이너 오케스트레이션** (AWS EKS)
- **무중단 배포 전략** (Kubernetes Rolling Update)
- **민감 정보의 안전한 관리** (환경 변수, `.env`, GitHub Secrets)

## 4. 기술 스택 (Tech Stack)

- **Application:** Java 21, Spring Boot 3.x, Spring Security, JPA, Gradle
- **Database:** PostgreSQL
- **CI/CD:** GitHub Actions, Docker, Docker Compose
- **Cloud (AWS):** ECR, EKS, VPC, IAM
- **IaC:** Terraform

## 5. 프로젝트 진행 기록 (Journey)

### Phase 1: 로컬 개발 환경 현대화
- ✅ H2 인메모리 데이터베이스를 프로덕션급인 **PostgreSQL**로 마이그레이션.
- ✅ Docker를 이용해 로컬 환경에 PostgreSQL 서버를 컨테이너로 실행.
- ✅ Spring Boot 애플리케이션이 외부 DB 컨테이너와 통신하도록 `application.yml` 설정.
- ✅ **환경 변수**를 도입하여 DB 비밀번호 및 OAuth 클라이언트 시크릿 등 민감 정보를 코드와 분리.
- ✅ '실행 환경'과 '테스트 환경'의 차이를 이해하고, `src/test/resources`에 별도 설정을 추가하여 **테스트 빌드 성공.**

### Phase 2: 애플리케이션 패키징 및 실행
- ✅ 프로덕션용 JRE 이미지(`eclipse-temurin:21-jre-alpine`)를 사용하는 **멀티 스테이지 `Dockerfile`** 작성.
- ✅ 애플리케이션과 데이터베이스를 하나의 세트로 관리하기 위한 **`docker-compose.yml`** 파일 작성 완료.
- ✅ `.gitignore` 파일을 설정하여 불필요하고 민감한 파일이 Git에 올라가지 않도록 방지.
- ✅ **`docker-compose up`** 명령어로 로컬 환경에서 전체 서비스가 동작하는 것을 확인.

### Phase 3: 지속적 통합 (CI) 파이프라인 구축
- ✅ GitHub Actions 워크플로우 (`ci.yml`) 초안 작성 및 실행.
- ✅ **AWS IAM Identity Center**를 통해 관리자 계정을 생성하고, **서비스 전용 IAM User**(`github-actions-ecr-pusher`)를 생성하여 보안 강화.
- ✅ GitHub Secrets에 AWS Access Key를 안전하게 등록.
- ✅ `git push` 시 자동으로 애플리케이션을 빌드하고 Docker 이미지를 생성하여 **AWS ECR에 푸시**하는 CI 파이프라인 완성.

### Phase 4: 인프라 구축 및 배포 (IaC & CD) - (진행 중)
- ➡️ **Terraform**을 사용하여 EKS 클러스터 및 관련 네트워크 인프라를 코드로 구축하는 단계 진행 중.
