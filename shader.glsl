float db(vec3 testp, vec3 c){
    vec3 q = abs(testp)-c;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

struct CastResult
{
    float dist;
    float refl;
    vec3 color;
};

CastResult dwm(vec3 testp, vec3 cbm){
    float ma = 200.0;
    
    float sh1 = distance(testp,vec3(-0.8,0.0,-0.5))-0.5;
    
    float sh2 = distance(testp,vec3( 0.8,0.0,-0.5))-0.5;
    
    float sh3 = db(testp+vec3(0.0,1.0,0.0),vec3(0.5,0.2,1));
    
    float sh4 = (1.0+testp.y)*1.5;
    
    float sh5 = distance(testp,vec3(0.0 ,0.2,1.0))-0.5;
    
    float mi = min(ma,min(sh4,min(sh3,min(sh2,min(sh1,sh5)))));
    
    vec3 c = vec3(texture(iChannel0, cbm).xyz);
    
    float reflection = 0.0;
    if (mi==sh1 || mi==sh2){
        c = vec3(1.0,0.0,0.0);
        //c = vec3(0.0,1.0,floor(mod(floor(testp.z)*0.5+testp.y+testp.x*0.5,1.0)*2.0));
    }else if (mi==sh3 || mi==sh4 || mi==sh5){
        float bro = clamp(floor(mod(floor(testp.z)*0.5+testp.y+testp.x*0.5,1.0)*2.0)+.5,.0,1.);
        reflection = 0.06;
        c = vec3(bro,0.0,0.0);
    }
    
    CastResult cr;
    cr.dist = mi;
    cr.refl = reflection;
    cr.color = c;
    
    return cr;
}

float d(vec3 testp){
    return dwm(testp, vec3(0.0)).dist;
}

vec3 calcNormal( in vec3 p ) // for function d(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(d(p+h.xyy) - d(p-h.xyy),
                           d(p+h.yxy) - d(p-h.yxy),
                           d(p+h.yyx) - d(p-h.yyx) ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col = vec3(0.5,0.6,1.0);
    
    vec3 lightfrom = normalize(vec3(0.0,1.0,-0.2));
    
    float yaw = (iMouse.x/iResolution.x-0.5)*3.5;
    float pitch = clamp(-(iMouse.y/iResolution.y)*1.0+0.02,-.92,0.0);
    
    //vec3 pos = vec3((uv.x-0.5)*0.2,(uv.y-0.5)*0.2,-12.0+cos(iTime)*5.0);
    //vec3 pos = vec3(-sin(iTime*0.2)*12.0,0.0,cos(iTime*0.2)*12.0);
    //vec3 pos = vec3(-sin(yaw)*12.0,0.0,cos(yaw)*12.0);
    //vec3 dir = vec3((uv.x-0.5)*0.5,(uv.y-0.5)*0.3,1.0);
    vec3 udir = vec3((uv.x-0.5),(uv.y-0.5)*.6,1.0);
    
    udir = vec3( //apply pitch
    udir.x,
    udir.y*cos(pitch)+udir.z*sin(pitch),
    udir.z*cos(pitch)-udir.y*sin(pitch)
    );
    
    vec3 dir = vec3( //apply yaw
    udir.x*cos(yaw)+udir.z*sin(yaw),
    udir.y,
    -udir.z*cos(yaw)+udir.x*sin(yaw)
    );
    /*vec3 dir = vec3(
    (uv.x-0.5)*cos(iTime*0.2)+sin(iTime*0.2),
    (uv.y-0.5)*0.6,
    (uv.x-0.5)*sin(iTime*0.2)-cos(iTime*0.2));*/
    
    dir = normalize(dir);
    
    vec3 pos = vec3(0.0,0.0,12.0);
    pos = vec3( //apply pitch
    pos.x,
    pos.y*cos(pitch)-pos.z*sin(pitch),
    pos.z*cos(pitch)+pos.y*sin(pitch)
    );
    pos = vec3( //apply yaw
    pos.x*cos(yaw)+pos.z*sin(-yaw),
    pos.y,
    pos.z*cos(yaw)-pos.x*sin(-yaw)
    );
    
    vec3 spos = pos;
    
    vec3 cubemap = vec3(texture(iChannel0, uv.x*dir).xyz);    
    col = cubemap;
    
    float cdis = 100.0;
    int maxstep = 400;
    vec3 mul = vec3(1.0);
    float nextInfluence = 1.0;
    
    
    bool hit = false;
    vec3 fhpos = vec3(1.0/0.0);
    
    while (maxstep>0 && cdis>0.06){
        maxstep-=1;
        CastResult cr = dwm(pos,uv.x*dir);
        cdis = cr.dist;
        pos = pos+dir*cdis*0.45;
        
        //dir+=vec3(0.0,-cdis*0.005,0.0);
        //dir = normalize(dir);
        
        if (cdis<.09){
            vec3 normal = calcNormal(pos);
            
            if (!hit) {
                hit=true;
                fhpos = pos;
            }
            
            float light = 0.5+abs(dot(lightfrom,normal)+0.6)*0.4;
            
            col = cr.color*nextInfluence*mul+col*(1.0-nextInfluence);
            
            col = col*light;
            
            nextInfluence = nextInfluence*cr.refl;
            mul*= cr.color;
            
            if (cr.refl<0.05){
                cdis=0.0;
            }else{
                cdis = 0.091;
                dir = reflect(dir,normal);
                pos = pos+dir*cdis*0.93;
                
            }
        }else{
            float freak = clamp(cdis*0.00002,0.0,1.0);
            col = vec3(texture(iChannel0, uv.x*dir).xyz)*freak+col*(1.0-freak);
        }
    }
    
    vec3 dif = fhpos-spos;
    float pdis = dot(dif,dif);
    float fog = clamp(1.0-clamp(pdis*3.0-600.0,0.0,1000.0)*0.0005,0.0,1.0);
    //col = vec3(fog);
    col = col*(fog)+vec3(1.0-fog)*cubemap;
    //col = vec3(fragCoord.y/255.0,fragCoord.x/255.0,0.5);
    
    // Output to screen
    fragColor = vec4(col,1.0);
} 
