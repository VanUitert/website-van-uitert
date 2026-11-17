/* Van Uitert website - gedrag
   1. De rode draad tekent mee met het scrollen en eindigt bij het slotblok.
   2. Secties schuiven in beeld, lijnen tekenen zichzelf, cijfers tellen op.
   3. Stations op de homepage klappen open.
   4. Menu op kleine schermen.
   5. Formulier: eerst Netlify Forms, anders het mailprogramma van de bezoeker. */
(function(){
  var main=document.querySelector('main');
  var rail=document.querySelector('.thread .rail');
  var stations=[].slice.call(document.querySelectorAll('.station'));
  var end=document.querySelector('.station.end');

  function yOf(el){return el.getBoundingClientRect().top+window.scrollY;}
  function draw(){
    if(!rail||!main)return;
    var mainTop=yOf(main);
    var tip=window.scrollY+window.innerHeight*0.62-mainTop;
    var max=end?yOf(end.querySelector('.wrap'))-mainTop+10:main.offsetHeight;
    if(tip>max)tip=max; if(tip<0)tip=0;
    rail.style.height=tip+'px';
    stations.forEach(function(s){
      var y=yOf(s.querySelector('.wrap'))-mainTop+2;
      s.classList.toggle('lit',y<=tip);
    });
  }
  window.addEventListener('scroll',draw,{passive:true});
  window.addEventListener('resize',draw);
  window.addEventListener('load',draw);
  draw();

  function count(el){
    var t=parseInt(el.getAttribute('data-count'),10),s=null;
    function f(ts){if(!s)s=ts;var p=Math.min((ts-s)/1200,1);el.textContent=Math.round((1-Math.pow(1-p,3))*t);if(p<1)requestAnimationFrame(f);}
    requestAnimationFrame(f);
  }
  if('IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){
      if(!e.isIntersecting)return;
      e.target.classList.add('in');
      if(e.target.classList.contains('track'))e.target.classList.add('drawn');
      [].forEach.call(e.target.querySelectorAll('[data-count]'),count);
      io.unobserve(e.target);
    });},{threshold:.2});
    [].forEach.call(document.querySelectorAll('.reveal,.track,.nums'),function(el){io.observe(el);});
  }else{
    [].forEach.call(document.querySelectorAll('.reveal'),function(el){el.classList.add('in');});
    [].forEach.call(document.querySelectorAll('.track'),function(el){el.classList.add('drawn');});
    [].forEach.call(document.querySelectorAll('[data-count]'),function(el){el.textContent=el.getAttribute('data-count');});
  }

  /* Stations: tekst staat in de pagina zelf (data-attributen), niet hier. */
  var panel=document.getElementById('detail');
  if(panel){
    var sts=[].slice.call(document.querySelectorAll('.st'));
    var close=function(){panel.classList.remove('open');sts.forEach(function(x){x.classList.remove('active');x.setAttribute('aria-expanded','false');});};
    sts.forEach(function(st){st.addEventListener('click',function(){
      if(st.classList.contains('active')){close();return;}
      close(); st.classList.add('active'); st.setAttribute('aria-expanded','true');
      panel.querySelector('.eyebrow').textContent='Station '+st.querySelector('.n').textContent;
      panel.querySelector('h3').textContent=st.querySelector('b').textContent;
      panel.querySelector('p').textContent=st.getAttribute('data-text');
      panel.querySelector('ul').innerHTML=st.getAttribute('data-facts').split('|').map(function(x){return '<li>'+x+'</li>';}).join('');
      var a=panel.querySelector('a'); a.setAttribute('href',st.getAttribute('data-href')); a.textContent=st.getAttribute('data-link')+' →';
      panel.classList.add('open'); panel.scrollIntoView({behavior:'smooth',block:'nearest'});
    });});
    panel.querySelector('.close').addEventListener('click',close);
  }

  var hdr=document.querySelector('header.site'), mb=document.querySelector('.menu-btn');
  if(hdr&&mb){mb.addEventListener('click',function(){var o=hdr.classList.toggle('open');mb.setAttribute('aria-expanded',o?'true':'false');mb.textContent=o?'Close':'Menu';});}

  [].forEach.call(document.querySelectorAll('form.form'),function(form){
    form.addEventListener('submit',function(ev){
      ev.preventDefault();
      var data=new FormData(form), pairs=[], lines=[];
      data.forEach(function(v,k){pairs.push(encodeURIComponent(k)+'='+encodeURIComponent(v)); if(k!=='form-name'&&k!=='bot-field'&&v)lines.push(k+': '+v);});
      var mail=function(){
        var to=form.getAttribute('data-mail')||'info@uitert.nl';
        window.location.href='mailto:'+to+'?subject='+encodeURIComponent(form.getAttribute('data-subject')||'Website')+'&body='+encodeURIComponent(lines.join('\n'));
      };
      var ok=function(){form.classList.add('sent');form.reset();};
      if(location.protocol.indexOf('http')!==0){mail();return;}
      fetch('/',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:pairs.join('&')})
        .then(function(r){if(r.ok)ok();else mail();}).catch(mail);
    });
  });
})();
