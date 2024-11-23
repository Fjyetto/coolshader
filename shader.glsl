float db(vec3 testp, vec3 c){
    vec3 q = abs(testp)-c;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

/*float d(vec3 testp){
    return min(
    100.0,
    min(distance(testp,vec3(-0.8,0.0,-0.5))-0.5,
    min(distance(testp,vec3(0.8,0.0,-0.5))-0.5,
    db(testp,vec3(0.5,0.2,1)))
    ));
}*/

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
        //float bro = floor(mod(floor(testp.z)*0.5+testp.y+testp.x*0.5,1.0)*2.0);
        reflection = 1.0;
        c = vec3(1.0);
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
    
    //vec3 pos = vec3((uv.x-0.5)*0.2,(uv.y-0.5)*0.2,-12.0+cos(iTime)*5.0);
    vec3 pos = vec3(-sin(iTime*0.2)*12.0,0.0,cos(iTime*0.2)*12.0);
    //vec3 dir = vec3((uv.x-0.5)*0.5,(uv.y-0.5)*0.3,1.0);
    vec3 dir = vec3(
    (uv.x-0.5)*cos(iTime*0.2)+sin(iTime*0.2),
    (uv.y-0.5)*0.6,
    (uv.x-0.5)*sin(iTime*0.2)-cos(iTime*0.2));
    
    dir = normalize(dir);
    
    col = vec3(texture(iChannel0, uv.x*dir).xyz);
    
    float cdis = 100.0;
    int maxstep = 100;
    float nextInflucence = 1.0;
    
    while (maxstep>0 && cdis>0.1){
        maxstep-=1;
        CastResult cr = dwm(pos,uv.x*dir);
        cdis = cr.dist;
        pos = pos+dir*cdis*0.9;
        
        if (cdis<.05){
            col = m[2]*nextInfluence+col*(1.0-nextInfluence);
            nextInfluence = nextInfluence*m[1];
            if (m[1]<0.05){
                cdis=0.0;
            }else{
                cdis = 0.11;
                vec3 normal = calcNormal(pos);
                dir = reflect(dir,normal);
                pos = pos+dir*cdis*0.93;
                
            }
        }
    }
    
    /*while (maxstep>0 && cdis>0.1){
        maxstep-=1;
        cdis = dwm(pos,uv.x*dir).x;
        pos = pos+dir*cdis;
        
        dir+=vec3(0.0,-cdis*0.006,0.0);
        dir=normalize(dir);
        
        if (cdis<.1) {
            hit = true;
            //maxstep=0;
            cdis = 0.0;
        }
    }
    
    if (hit){
        vec3 normal = calcNormal(pos);
        vec3 lightfrom = normalize(vec3(0.0,1.0,-0.2));
        float light = 0.5+abs(dot(lightfrom,normal)+0.6)*0.4;
        vec3 alb = dwm(pos,uv.x*dir).yzw;
        col = alb*light;
        
        if (alb==vec3(1.0,1.0,1.0) && maxstep>7){
            dir = reflect(dir,normal);
            //col = vec3(0.0,0.0,0.0);
            
            cdis = 50.0;

            hit = false;
            
            vec3 lcol = col;
            pos = pos+dir*0.2;

            while (maxstep>0 && cdis>0.1){
                maxstep-=1;
                vec4 buh = dwm(pos,uv.x*dir);
                cdis = buh.x;
                lcol = buh.yzw;
                pos = pos+dir*cdis;
                
                dir+=vec3(0.0,-cdis*0.001,0.0);
                dir=normalize(dir);

                if (cdis<.1) {
                    hit = true;
                    //maxstep=0;
                    cdis = 0.0;
                }
            }
            col = (col*0.3+lcol*0.7);
        }
    }*/
    
    

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    // Output to screen
    fragColor = vec4(col,1.0);
} 
