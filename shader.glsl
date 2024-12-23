float db(vec3 testp, vec3 c){
    vec3 q = abs(testp)-c;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

struct CastResult
{
    float dist;
    float refl;
    float tran;
    vec3 color;
};

CastResult dwm(vec3 testp, vec3 cbm){
    float ma = 200.0;
    CastResult cr;
    
    float sh1 = distance(testp,vec3(-1.6,0.0,-0.5))-0.5;
    
    float sh2 = distance(testp,vec3( 1.6,0.0,-0.5))-0.5;
    
    float sh3 = db(testp+vec3(0.0,1.0,0.0),vec3(0.5,0.2,1));
    
    float sh4 = (testp.y+1.0)
    +max((sin(testp.x*16.3)*cos(testp.z*16.3))*0.03,-.01)
    +(sin(testp.x*0.3)*cos(testp.z*0.3))*0.8;
    //(1.0+testp.y)*1.5;
    
    float sh5 = distance(testp,vec3(0.0 ,0.2,1.0))-0.5;
    vec3 sqp = vec3(2.0,0.0,-4.0);
    vec3 offs = testp-sqp; 
    
    float da = 6.0;
    
    float wallx = abs(testp.x-6.0);
    float wallx2 = abs(testp.x+18.0);
    
    float walla = 600.0;//((abs(mod(offs.x,da)-da*0.5)*.1)+(abs(mod(offs.z+2.0,da)-da*0.5)*0.1)+(abs(offs.y-2.0)*0.1))-0.05;
    
    float mi = min(min(ma,min(sh4,min(sh3,min(sh2,min(sh1,sh5))))),min(wallx,wallx2));
    
    vec3 c = vec3(texture(iChannel0, cbm).xyz);
    
    if (mi==sh1 || mi==sh2){
        c = vec3(1.0,0.0,0.0);
        //c = vec3(0.0,1.0,floor(mod(floor(testp.z)*0.5+testp.y+testp.x*0.5,1.0)*2.0));
    }else if (mi==sh3 || mi==sh5 || mi==wallx || mi==wallx2){
        float bro = clamp(floor(mod(floor(testp.z)*0.5+testp.y+testp.x*0.5,1.0)*2.0)+.5,.0,1.);
        cr.refl = 0.96;
        c = vec3(1.0,1.0,1.0);
    }else if (mi==sh4){
        c = vec3(0.4,0.7,0.1);
    }else if (mi==walla){
        c = vec3(0.1,0.65,1.0);
        cr.refl = 0.3;
    }
    
    if (mi==sh2) {
        cr.tran = 1.0;
        cr.refl = 0.0;
    }
    
    
    cr.dist = mi;
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
    //return normalize( vec3(d(p+h.xyy) - d(p), d(p+h.yxy) - d(p), d(p+h.yyx) - d(p)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col = vec3(0.5,0.6,1.0);
    
    vec3 lightfrom = normalize(vec3(0.0,1.0,-0.2));
    
    float yaw = (iMouse.x/iResolution.x-0.5)*7.2;
    float pitch = clamp(-(iMouse.y/iResolution.y)*2.1+0.02,-1.22,0.1);
    
    //vec3 pos = vec3((uv.x-0.5)*0.2,(uv.y-0.5)*0.2,-12.0+cos(iTime)*5.0);
    //vec3 pos = vec3(-sin(iTime*0.2)*12.0,0.0,cos(iTime*0.2)*12.0);
    //vec3 pos = vec3(-sin(yaw)*12.0,0.0,cos(yaw)*12.0);
    //vec3 dir = vec3((uv.x-0.5)*0.5,(uv.y-0.5)*0.3,1.0);
    vec3 udir = vec3((uv.x-0.5),(uv.y-0.5)*.6,1.0);
    //vec3 udir = vec3(cos((uv.x-0.25)*3.14159*2.0),(uv.y-0.5)*1.6,sin((uv.x-0.25)*3.14159*2.0));
    
    
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
    
    float cdis = 800.0;
    int maxstep = 700;
    vec3 mul = vec3(1.0);
    float nextInfluence = 1.0;
    
    
    bool hit = false;
    vec3 fhpos = vec3(1.0/0.0);
    bool escape = false;
    
    while (maxstep>0 && cdis>0.06){
        maxstep-=1;
        CastResult cr = dwm(pos,uv.x*dir);
        cdis = cr.dist;
        pos = pos+dir*cdis*0.25;//.45
        
        //dir+=vec3(0.0,-cdis*0.005,0.0);
        //dir = normalize(dir);
        if (cdis>=.1 && escape){
            escape=false;
            col = vec3(1.0);
            pos = pos+dir;
        }
        
        if (cdis<.09 && !escape){
            vec3 normal = calcNormal(pos);
            
            if (!hit) {
                hit=true;
                fhpos = pos;
                if (cr.tran<=0.01) col = cr.color;
            }
            
            float light = 0.5+abs(dot(lightfrom,normal)+0.6)*0.4;
            
            col = cr.color*nextInfluence*mul+col*(1.0-nextInfluence);
            
            col = col*light;
            
            if (cr.tran>0.01){
                escape = true;
                nextInfluence = nextInfluence*cr.tran;
                mul*= cr.color;
                col = col.xxx;
                
                cdis = 0.191;
                //dir = refract(dir,normal,1.45);
                pos = pos+dir*cdis;
            }
            
            if (cr.refl<0.05){
                cdis = 0.0;
            }else{
                nextInfluence = nextInfluence*cr.refl;
                mul*= cr.color;
                cdis = 0.091;
                dir = reflect(dir,normal);
                pos = pos+dir*cdis*0.93;
                //maxstep-=30;
                
            }
        }else{
            float freak = clamp(cdis*0.00002,0.0,1.0);
            col = vec3(texture(iChannel0, uv.x*dir).xyz)*freak+col*(1.0-freak);
        }
    }
    
    vec3 dif = fhpos-spos;
    float pdis = dot(dif,dif);
    //float fog = clamp(1.0-clamp(pdis*2.0-900.0,0.0,1000.0)*0.0005,0.0,1.0); // humid half fog
    float fog = clamp(1.0-clamp(pdis*1.0-300.0,0.0,1000.0)*0.001,0.0,1.0); // serious full fog
    //col = vec3(fog);
    col = col*(fog)+vec3(1.0-fog)*vec3(1.0);
    //col = vec3(nextInfluence*16.0);
    //col = vec3(fragCoord.y/255.0,fragCoord.x/255.0,0.5);
    
    // Output to screen
    fragColor = vec4(col,1.0);
} 
