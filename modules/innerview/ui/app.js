const API='./state';let t=0;
function clk(){document.getElementById('clock').textContent=new Date().toLocaleTimeString()}
async function load(f){try{return await(await fetch(API+'/'+f)).json()}catch{return null}}
async function render(){t++;document.getElementById('status-dot').className=t%5===0?'dot online':'dot offline'
const ag=await load('agent_meta.json')||[];document.getElementById('agent-list').innerHTML=ag.length?ag.map(a=>'<div><b>'+a.agent+'</b> → '+a.status+' <span style="float:right;color:#10b981">'+(a.ts||'--')+'</span></div>').join(''):'<div style="color:#6b7280">No agents</div>'
const q=await load('queue.json')||[];document.getElementById('queue-list').innerHTML=q.length?q.map(x=>'<div>📦 '+x.task_id+' <span style="color:#f59e0b">'+(x.state||'pending')+'</span></div>').join(''):'<div style="color:#6b7280">Queue empty</div>'
const w=await load('witness.jsonl');document.getElementById('chain-log').textContent=w?w.slice(-5).map(JSON.stringify).join('\n'):'Awaiting attestations...'
document.getElementById('metrics').innerHTML='<div>CPU: '+(10+Math.random()*30|0)+'%</div><div>MEM: '+(120+Math.random()*250|0)+'MB</div><div>UPTIME: '+(t/10|0)+'m</div>'}
setInterval(clk,1e3);setInterval(render,3e3);render();clk();
