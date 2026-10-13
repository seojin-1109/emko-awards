export async function onRequestPost({request,env}) {
  const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
  if(new URL(request.url).origin!==request.headers.get('Origin'))return json({error:'허용되지 않은 요청입니다.'},403);
  const token=request.headers.get('Authorization');
  if(!token?.startsWith('Bearer '))return json({error:'관리자 로그인이 필요합니다.'},401);
  if(!env.SUPABASE_URL||!env.SUPABASE_SERVICE_ROLE_KEY)return json({error:'서버 연결 설정이 필요합니다.'},503);
  try {
    const base=env.SUPABASE_URL.replace(/\/$/,'');
    const userResponse=await fetch(base+'/auth/v1/user',{headers:{apikey:env.SUPABASE_SERVICE_ROLE_KEY,Authorization:token}});
    if(!userResponse.ok)return json({error:'로그인이 만료되었습니다. 다시 로그인해주세요.'},401);
    const user=await userResponse.json();
    const roleResponse=await fetch(base+'/rest/v1/rpc/portal_is_admin',{method:'POST',headers:{apikey:env.SUPABASE_SERVICE_ROLE_KEY,Authorization:token,'Content-Type':'application/json'},body:'{}'});
    if(!roleResponse.ok||await roleResponse.json()!==true)return json({error:'관리자 권한이 없습니다.'},403);
    if(Number(request.headers.get('Content-Length')||0)>1048576)return json({error:'문서 정보가 너무 큽니다.'},413);
    const body=await request.text();if(body.length>1048576)return json({error:'문서 정보가 너무 큽니다.'},413);
    const p=JSON.parse(body);
    const result=await fetch(base+'/rest/v1/rpc/portal_save_state',{method:'POST',headers:{apikey:env.SUPABASE_SERVICE_ROLE_KEY,Authorization:'Bearer '+env.SUPABASE_SERVICE_ROLE_KEY,'Content-Type':'application/json'},body:JSON.stringify({p_key:p.key,p_value:p.value,p_revision:p.revision,p_actor:user.id,p_ip:request.headers.get('CF-Connecting-IP'),p_action:p.entry?.action||'',p_detail:p.entry?.detail||''})});
    const data=await result.json();if(!result.ok)return json({error:data.message||'저장에 실패했습니다.'},result.status===409?409:400);
    return json(data);
  }catch{return json({error:'저장 요청을 처리하지 못했습니다. 설정과 연결을 확인해주세요.'},500)}
}
