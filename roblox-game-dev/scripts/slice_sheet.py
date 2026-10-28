"""Key out a flat magenta (#FF00FF) background and slice an AI-generated icon sheet into transparent PNGs.
Proven on the Pet Legends pack (Oct 2026). Usage: edit the grid(...) calls at the bottom
(sheet name, rows, cols, output names), put sheets in <dir>/src/, run: python3 slice_sheet.py <dir>
Keying uses a flood-fill from the image border (not a global colour key), so pink/purple objects survive.
Each grid cell keeps only its largest object (drops neighbour slivers). Output: <dir>/out/<name>.png, 512x512.
Needs: pillow, numpy, scipy.
"""
import sys,numpy as np
from PIL import Image
from scipy import ndimage
D=sys.argv[1]
def key(im):
    a=np.asarray(im.convert('RGB')).astype(np.int32)
    r,g,b=a[...,0],a[...,1],a[...,2]
    # distance to pure magenta; background = connected region touching the border
    dist=np.sqrt((r-255)**2+(g-0)**2+(b-255)**2)
    cand=dist<110
    lab,n=ndimage.label(cand)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bg=np.isin(lab,list(border))
    # also enclosed pure-magenta holes (gaps between legs etc.)
    bg|=dist<40
    fg=~bg
    fg=ndimage.binary_opening(fg,iterations=1)
    # soft edge + despill on a 2px ring
    ring=ndimage.binary_dilation(bg,iterations=2)&fg
    out=a.copy()
    out[ring,0]=np.minimum(out[ring,0],out[ring,1]+30); out[ring,2]=np.minimum(out[ring,2],out[ring,1]+30)
    alpha=np.where(fg,255,0).astype(np.uint8)
    alpha=np.asarray(Image.fromarray(alpha).filter(__import__('PIL.ImageFilter',fromlist=['x']).GaussianBlur(0.7)))
    return Image.fromarray(np.dstack([out.astype(np.uint8),alpha]),'RGBA')
def blobs(rgba,minarea):
    al=np.asarray(rgba)[...,3]>0
    lab,n=ndimage.label(ndimage.binary_dilation(al,iterations=6))
    objs=ndimage.find_objects(lab); res=[]
    for i,sl in enumerate(objs):
        h=sl[0].stop-sl[0].start; w=sl[1].stop-sl[1].start
        if h*w<minarea: continue
        res.append(sl)
    res.sort(key=lambda s:(round(s[0].start/ (rgba.height/8)), s[1].start))
    return res
def save(rgba,sl,name,size=512):
    c=rgba.crop((sl[1].start,sl[0].start,sl[1].stop,sl[0].stop))
    s=max(c.size); pad=int(s*0.06); canvas=Image.new('RGBA',(s+2*pad,s+2*pad),(0,0,0,0))
    canvas.paste(c,((s-c.width)//2+pad,(s-c.height)//2+pad),c)
    canvas.resize((size,size),Image.LANCZOS).save(f'{D}/out/{name}.png')

def grid(name,rows,cols,names,size=512):
    ext={'pets':'jpg','eggs':'jpg','icons':'png','shop':'jpg'}[name]
    rg=key(Image.open(f'{D}/src/{name}.{ext}'))
    H=rg.height; W=rg.width
    if name=='pets': H=int(rg.height*0.66)   # pets occupy top ~2/3
    ch=H//rows; cw=W//cols; k=0
    for i in range(rows):
        for j in range(cols):
            if k>=len(names): return
            part=rg.crop((j*cw,i*ch,(j+1)*cw,(i+1)*ch))
            arr=np.array(part); al=arr[...,3]>20
            lab,n=ndimage.label(ndimage.binary_dilation(al,iterations=8))
            if n>1:
                sizes=ndimage.sum(al,lab,range(1,n+1)); keep=np.argmax(sizes)+1
                cx=[ndimage.center_of_mass(al,lab,q) for q in range(1,n+1)]
                for q in range(1,n+1):
                    # drop small blobs touching the cell edge (neighbour slivers)
                    if q==keep: continue
                    m=lab==q; ys,xs=np.where(m)
                    touches=ys.min()==0 or xs.min()==0 or ys.max()==m.shape[0]-1 or xs.max()==m.shape[1]-1
                    if touches or sizes[q-1]<0.02*sizes[keep-1]: arr[m,3]=0
                part=Image.fromarray(arr,'RGBA')
            bb=part.getbbox()
            if not bb: k+=1; continue
            c=part.crop(bb); s=max(c.size); pad=int(s*.05)
            cv=Image.new('RGBA',(s+2*pad,s+2*pad),(0,0,0,0)); cv.paste(c,((s-c.width)//2+pad,(s-c.height)//2+pad),c)
            cv.resize((size,size),Image.LANCZOS).save(f'{D}/out/{names[k]}.png'); k+=1
grid('pets',2,4,['pet_dog','pet_cat','pet_bunny','pet_fox','pet_dragon','pet_phoenix','pet_axolotl'])
grid('eggs',1,3,['egg_basic','egg_forest','egg_mythic'])
grid('icons',4,4,['ic_coin','ic_gem','ic_paw','ic_egg','ic_rebirth','ic_quest','ic_daily','ic_trade','ic_trophy','ic_index','ic_settings','ic_lock','ic_trash','ic_star','ic_luck','ic_speed'])
grid('shop',3,3,['shop_vip','shop_2xcoins','shop_slots','shop_autohatch','shop_fasthatch','shop_lucky','shop_gems_small','shop_gems_chest','shop_gift'])
lg=key(Image.open(f'{D}/src/logo.png')); lg.crop(lg.getbbox()).save(f'{D}/out/logo.png')
Image.open(f'{D}/src/backdrop.png').convert('RGB').save(f'{D}/out/bg_loading.jpg',quality=88)
