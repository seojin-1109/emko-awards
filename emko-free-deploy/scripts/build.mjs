import {readFileSync,writeFileSync} from 'node:fs';
const url=process.env.SUPABASE_URL;
const key=process.env.SUPABASE_ANON_KEY;
if(!url||!key)throw new Error('SUPABASE_URL 및 SUPABASE_ANON_KEY 환경변수를 설정하세요.');
if(/service_role|sb_secret_/.test(key))throw new Error('브라우저 설정에는 공개용 키만 사용할 수 있습니다.');
if(key.split('.').length===3){let payload;try{payload=JSON.parse(Buffer.from(key.split('.')[1],'base64url'))}catch{}if(payload?.role==='service_role')throw new Error('service_role 키를 공개할 수 없습니다.')}
writeFileSync('public/config.js','window.EMKO_CONFIG = '+JSON.stringify({supabaseUrl:url.replace(/\/$/,''),supabaseAnonKey:key})+';\n');
console.log('공개 연결 설정 준비 완료');
