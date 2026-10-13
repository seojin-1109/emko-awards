# EMKO 상장·인증서 — 무료 범위 배포 준비 코드

Cloudflare Pages + Pages Functions + Supabase 구성입니다. Python 서버는 사용하지 않습니다.
아직 Supabase 프로젝트나 사이트가 생성된 상태가 아닙니다. 연결 전에는 로그인/저장을 실행할 수 없습니다.

## 파일
- public/index.html: 기존 화면과 관리자 편집 기능
- public/config.js: 공개용 Supabase 주소/키 (계정 비밀번호 없음)
- functions/api/save.js: 관리자 검증 및 실제 접속 IP를 포함한 저장 요청
- schema.sql: 데이터, 관리자 허용 목록, 작업 이력, 파일 버킷과 접근 정책
- scripts/build.mjs: 배포 시 공개 연결 설정 생성

## 다음 단계에서 필요한 설정
1. Supabase Free 프로젝트 생성
2. SQL Editor에서 schema.sql 실행
3. Authentication에서 공개 회원가입 허용을 끄고, Users에서 관리자 이메일/비밀번호로 계정 생성
4. 생성된 관리자 UID를 사용해 다음 SQL 실행:
   insert into public.portal_admins(user_id) values ('관리자 UID');
   일반 계정으로 로그인해도 이 허용 목록에 없으면 관리자 접근이 거부됩니다.
5. GitHub 비공개 저장소에 프로젝트 파일을 업로드
6. Cloudflare Pages에서 GitHub 저장소 연결
   빌드 명령: npm run build
   출력 디렉터리: public
   환경 변수: SUPABASE_URL, SUPABASE_ANON_KEY
   서버 비밀 변수: SUPABASE_SERVICE_ROLE_KEY (암호화 Secret으로 설정)
   위 설정을 Production/Preview 각각 필요한 환경에 적용
   service_role은 서버 함수에서만 사용하며 public/config.js에 넣으면 안 됩니다.
7. 배포 후 pages.dev 주소로 접속

Pages Functions를 사용하므로 파일을 끌어놓는 방식의 단순 정적 업로드는 사용하지 않습니다.
관리자 비밀번호는 Supabase에만 설정합니다. 코드나 GitHub에 기록하지 않습니다.
Cloudflare 무료 주소는 이름 사용 가능 여부에 따라 결정됩니다. 원하는 별도 도메인은 무료 제공되지 않습니다.

## 저장 및 보안
일반 사용자에게 문서/로고 파일은 공개됩니다. 파일 버킷도 공개입니다.
로그인 후 관리자 허용 목록에 있는 사용자만 파일을 업로드할 수 있습니다.
문서 수정은 서버 함수가 Supabase 인증 토큰을 검증한 뒤 수행합니다.
시각과 IP는 서버 측에서 기록하고, 이력은 관리자에게만 반환됩니다.
문서 변경과 작업 이력은 하나의 데이터베이스 트랜잭션으로 저장됩니다.
동시 수정 시 기존 변경을 덮어쓰지 않고 새로고침을 요청합니다.
파일 업로드 후 정보 저장이 실패하거나 파일을 교체/문서 삭제하면 이전 파일이 Storage에 남을 수 있습니다. Storage 관리 화면에서 불필요 파일을 정리하세요.
기존 HTML/로컬 Python 서버 자료는 자동 이전되지 않습니다.
무료 플랜의 저장용량/전송량 제한과 비활성 프로젝트 일시 중지 정책이 적용됩니다.
회사 운영 전 로그인/비로그인 권한, 파일 업로드/다운로드, 다른 기기 조회, 이력 기록을 실제 연결 환경에서 점검해야 합니다.

## 검증 범위
JavaScript 문법과 서버 함수의 권한 거부/인증 저장 흐름은 로컬 검증합니다.
Supabase 프로젝트가 아직 없으므로 실제 PostgreSQL 정책 실행과 클라우드 통합 테스트는 다음 연결 단계에서 진행합니다.
