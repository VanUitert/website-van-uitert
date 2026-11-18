using System; using System.Drawing; using System.Drawing.Drawing2D; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Lut {
  public const int N = 17;
  public static double[] sum = new double[N*N*N*3]; public static double[] wgt = new double[N*N*N];
  public static float[] off = new float[N*N*N*3];
  public static void Reset() { Array.Clear(sum,0,sum.Length); Array.Clear(wgt,0,wgt.Length); }
  public static Bitmap Schaal(Image src, int w, int h) { var b = new Bitmap(w, h, PixelFormat.Format24bppRgb); using (var g = Graphics.FromImage(b)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.PixelOffsetMode = PixelOffsetMode.HighQuality; g.Clear(Color.White); using (var ia = new ImageAttributes()) { ia.SetWrapMode(WrapMode.TileFlipXY); g.DrawImage(src, new Rectangle(0,0,w,h), 0, 0, src.Width, src.Height, GraphicsUnit.Pixel, ia); } } return b; }
  static byte[] Lees(Bitmap b, out int stride) { var d = b.LockBits(new Rectangle(0,0,b.Width,b.Height), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb); stride = d.Stride; var buf = new byte[stride*b.Height]; Marshal.Copy(d.Scan0, buf, 0, buf.Length); b.UnlockBits(d); return buf; }
  public static double Corr(Bitmap a, Bitmap e) { int s1, s2; var A = Lees(a, out s1); var E = Lees(e, out s2); double sa=0,se=0,saa=0,see=0,sae=0; int n=0;
    for (int y=0;y<a.Height;y++) for (int x=0;x<a.Width;x++) { int i=y*s1+x*3, j=y*s2+x*3; double la=0.11*A[i]+0.59*A[i+1]+0.3*A[i+2], le=0.11*E[j]+0.59*E[j+1]+0.3*E[j+2]; sa+=la; se+=le; saa+=la*la; see+=le*le; sae+=la*le; n++; }
    double cov=sae/n-(sa/n)*(se/n), va=saa/n-(sa/n)*(sa/n), ve=see/n-(se/n)*(se/n); return cov/Math.Sqrt(va*ve+1e-9); }
  public static void Train(Bitmap a, Bitmap e) { int s1, s2; var A = Lees(a, out s1); var E = Lees(e, out s2);
    for (int y=0;y<a.Height;y++) for (int x=0;x<a.Width;x++) { int i=y*s1+x*3, j=y*s2+x*3;
      double fb=A[i]/255.0*(N-1), fg=A[i+1]/255.0*(N-1), fr=A[i+2]/255.0*(N-1);
      int b0=Math.Min((int)fb,N-2), g0=Math.Min((int)fg,N-2), r0=Math.Min((int)fr,N-2); double db=fb-b0, dg=fg-g0, dr=fr-r0;
      for (int k=0;k<8;k++) { int kb=k&1, kg=(k>>1)&1, kr=(k>>2)&1; double w=(kb==1?db:1-db)*(kg==1?dg:1-dg)*(kr==1?dr:1-dr); if (w<=0) continue; int node=((r0+kr)*N+(g0+kg))*N+(b0+kb);
        sum[node*3]+=w*(E[j]-A[i]); sum[node*3+1]+=w*(E[j+1]-A[i+1]); sum[node*3+2]+=w*(E[j+2]-A[i+2]); wgt[node]+=w; } } }
  public static int Bouw(double min) { int T=N*N*N; var ok=new bool[T]; int gevuld=0;
    for (int n=0;n<T;n++) if (wgt[n]>=min) { ok[n]=true; gevuld++; for (int c=0;c<3;c++) off[n*3+c]=(float)(sum[n*3+c]/wgt[n]); }
    int rest=T-gevuld; int[] d={1,-1,N,-N,N*N,-N*N};
    while (rest>0) { var nieuw=new System.Collections.Generic.List<int>(); var val=new System.Collections.Generic.List<float[]>();
      for (int r=0;r<N;r++) for (int g=0;g<N;g++) for (int b=0;b<N;b++) { int n=(r*N+g)*N+b; if (ok[n]) continue; float[] s=new float[3]; int cnt=0;
        if (b>0&&ok[n-1]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n-1)*3+c];} if (b<N-1&&ok[n+1]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n+1)*3+c];}
        if (g>0&&ok[n-N]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n-N)*3+c];} if (g<N-1&&ok[n+N]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n+N)*3+c];}
        if (r>0&&ok[n-N*N]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n-N*N)*3+c];} if (r<N-1&&ok[n+N*N]){cnt++;for(int c=0;c<3;c++)s[c]+=off[(n+N*N)*3+c];}
        if (cnt>0) { for(int c=0;c<3;c++) s[c]/=cnt; nieuw.Add(n); val.Add(s); } }
      if (nieuw.Count==0) break; for (int i=0;i<nieuw.Count;i++) { ok[nieuw[i]]=true; for(int c=0;c<3;c++) off[nieuw[i]*3+c]=val[i][c]; } rest-=nieuw.Count; }
    // lichte gladstrijking
    var cp=(float[])off.Clone();
    for (int r=0;r<N;r++) for (int g=0;g<N;g++) for (int b=0;b<N;b++) { int n=(r*N+g)*N+b; for (int c=0;c<3;c++) { float s=0; int cnt=0;
        if (b>0){s+=cp[(n-1)*3+c];cnt++;} if (b<N-1){s+=cp[(n+1)*3+c];cnt++;} if (g>0){s+=cp[(n-N)*3+c];cnt++;} if (g<N-1){s+=cp[(n+N)*3+c];cnt++;} if (r>0){s+=cp[(n-N*N)*3+c];cnt++;} if (r<N-1){s+=cp[(n+N*N)*3+c];cnt++;}
        off[n*3+c]=0.6f*cp[n*3+c]+0.4f*s/cnt; } }
    return gevuld; }
  public static void Pas(Bitmap bmp) { var d = bmp.LockBits(new Rectangle(0,0,bmp.Width,bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb); int st=d.Stride; var buf=new byte[st*bmp.Height]; Marshal.Copy(d.Scan0, buf, 0, buf.Length);
    for (int y=0;y<bmp.Height;y++) for (int x=0;x<bmp.Width;x++) { int i=y*st+x*3;
      double fb=buf[i]/255.0*(N-1), fg=buf[i+1]/255.0*(N-1), fr=buf[i+2]/255.0*(N-1);
      int b0=Math.Min((int)fb,N-2), g0=Math.Min((int)fg,N-2), r0=Math.Min((int)fr,N-2); double db=fb-b0, dg=fg-g0, dr=fr-r0; double o0=0,o1=0,o2=0;
      for (int k=0;k<8;k++) { int kb=k&1, kg=(k>>1)&1, kr=(k>>2)&1; double w=(kb==1?db:1-db)*(kg==1?dg:1-dg)*(kr==1?dr:1-dr); int node=((r0+kr)*N+(g0+kg))*N+(b0+kb); o0+=w*off[node*3]; o1+=w*off[node*3+1]; o2+=w*off[node*3+2]; }
      buf[i]=(byte)Math.Max(0,Math.Min(255,Math.Round(buf[i]+o0))); buf[i+1]=(byte)Math.Max(0,Math.Min(255,Math.Round(buf[i+1]+o1))); buf[i+2]=(byte)Math.Max(0,Math.Min(255,Math.Round(buf[i+2]+o2))); }
    Marshal.Copy(buf, 0, d.Scan0, buf.Length); bmp.UnlockBits(d); }
  public static double Fout(Bitmap a, Bitmap e) { int s1, s2; var A = Lees(a, out s1); var E = Lees(e, out s2); double s=0; long n=0; for (int y=0;y<a.Height;y++) for (int x=0;x<a.Width*3;x++) { s+=Math.Abs(A[y*s1+x]-E[y*s2+x]); n++; } return s/n; }
  public static void Bewaar(string pad) { var b=new byte[off.Length*4]; Buffer.BlockCopy(off,0,b,0,b.Length); System.IO.File.WriteAllBytes(pad,b); }
  public static void Laad(string pad) { var b=System.IO.File.ReadAllBytes(pad); Buffer.BlockCopy(b,0,off,0,b.Length); }
}
