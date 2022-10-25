# NRM
NRM由四张图构成角色渲染，亮部贴图，阴影贴图图，ilm贴图和细节贴图。

**原始模型**

<img align="left" width="600" height="400" src="../img/nrm_model.png">

## 1.亮度
**亮部贴图RGBA**

<img align="left" width="600" height="400" src="../img/skin08base.png">

**亮部贴图Alpha**

用于区分人物的皮肤区域以及非皮肤区域。
<img align="left" width="600" height="400" src="../img/skin08base_a.png">

## 2.阴影
**暗部颜色RGBA**

<img align="left" width="600" height="400" src="../img/skin08sss.png">

**暗部贴图Alpha**

用于做某些mask使用。
<img align="left" width="600" height="400" src="../img/skin08sss_a.png">

## 3.LightMap
**R通道**
控制高光强度

<img align="left" width="600" height="400" src="../img/ilm_r.png">

**G通道**
偏移光照，越黑部分越接近阴影，越白部分越接近亮部。128中度灰不会对原来光线进行偏移。

<img align="left" width="600" height="400" src="../img/ilm_g.png">

**B通道**
控制高光范围大小（光滑度）越黑部分高光越小，纯黑区域五高光。

<img align="left" width="600" height="400" src="../img/ilm_b.png">

**Alpha通道**
一张描线图，记录描线，内描线。

<img align="left" width="600" height="400" src="../img/ilm_a.png">

## 4.DetailMap
**Detail的RGBA**
使用第二套UV采样，也是描线图。但UV分部并不严格。按照第二套UV做点缀使用。

<img align="left" width="600" height="400" src="../img/detail.png">



