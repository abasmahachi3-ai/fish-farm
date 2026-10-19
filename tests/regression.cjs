const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const html=fs.readFileSync('index.html','utf8');
const script=html.match(/<script type="module">([\s\S]*?)<\/script>/)[1];
new vm.Script(script.replace(/^import .*;$/m,''));
function get(start,end,extra=''){return vm.runInNewContext(script.slice(script.indexOf(start),script.indexOf(end,script.indexOf(start)))+extra,{atob,Date,JSON,Number,Set,Error});}
test('only browser-safe Supabase keys are accepted',()=>{
 const check=get('function publicKey','function csvCell',';publicKey');
 assert.equal(check('sb_publishable_abc123'),true);
 for(const role of ['anon','service_role','authenticated']){
 const jwt='eyJ.'+Buffer.from(JSON.stringify({role})).toString('base64url')+'.sig';
 assert.equal(check(jwt),role==='anon');
 }
 assert.equal(check('sb_secret_abcd'),false);assert.equal(check('bad'),false);
});
test('CSV formula injection is neutralized',()=>{
 const check=get('function csvCell','function validDate',';csvCell');
 for(const text of ['=HYPERLINK("evil")',' +1','@SUM(1)','\t-2'])assert.ok(check(text).startsWith("'"));
 assert.equal(check('อาหารเช้า'),'อาหารเช้า');
});
test('imports reject impossible dates',()=>{
 const check=get('function validDate','function config',';validDate');
 assert.equal(check('2026-02-30'),false);assert.equal(check('2026-10-19'),true);assert.equal(check('19/10/2026'),false);
});
test('calculations use numeric sale counts and latest weighing date',()=>{
 const calc=get('function calc','function draw',`;batch={stocked:300,initial_g:10,fry_cost:450};entries=[{kind:'sample',qty:200},{kind:'sale',fish_count:'20',qty:3,amount:180},{kind:'sample',qty:100},{kind:'death',fish_count:5},{kind:'feed',qty:10,amount:300}];calc`);
 const result=calc();assert.equal(result.remaining,275);assert.equal(result.weight,200);assert.equal(result.opCost,750);assert.equal(result.profit,-570);assert.equal(result.fcr,10/55);
});
test('pagination reads beyond 1000 and filters the selected batch on server',async()=>{
 const calls=[];let offset=0;
 const context={farm:{id:'farm'},sb:{from(table){return {select(){return this},eq(k,v){calls.push([k,v]);return this},order(){return this},async range(a,b){offset=a;return {data:Array.from({length:a<1000?500:a===1000?1:0},(_,i)=>({id:a+i}))}}}}}};
 const query=vm.runInNewContext(script.slice(script.indexOf('async function query'),script.indexOf('let refreshing'))+';query',context);
 assert.equal((await query('entries','*','batch')).length,1001);assert.equal(offset,1001);assert.ok(calls.some(([k,v])=>k==='batch_id'&&v==='batch'));
});
test('database setup remains untouched and UI never runs migrations',()=>{
 assert.equal(script.includes("rpc('exec_sql'"),false);
 assert.ok(script.includes("sb.from('entries').insert(rows)"));
 assert.equal(script.includes('rows.slice(i,i+100)'),false);
});
