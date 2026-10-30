import type { AppData, Product, Order, Customer, Invoice, OrderStatus } from '../types';
const day=(n:number)=>new Date(Date.now()-n*86400000).toISOString();
const products:Product[]=[
 {id:'p1',name:'Everyday Canvas Tote',category:'Accessories',status:'Active',description:'A durable, everyday canvas carryall.',updatedAt:day(1),variants:[{id:'v1',name:'Natural',sku:'TOTE-NAT',price:2800,stock:42,threshold:10},{id:'v2',name:'Ink',sku:'TOTE-INK',price:2800,stock:8,threshold:10}]},
 {id:'p2',name:'Ribbed Cotton Tee',category:'Apparel',status:'Active',description:'Soft organic cotton with a relaxed fit.',updatedAt:day(2),variants:[{id:'v3',name:'Small / Chalk',sku:'TEE-S-CHK',price:3600,stock:24,threshold:8},{id:'v4',name:'Medium / Chalk',sku:'TEE-M-CHK',price:3600,stock:31,threshold:8},{id:'v5',name:'Large / Olive',sku:'TEE-L-OLV',price:3800,stock:5,threshold:8}]},
 {id:'p3',name:'Ceramic Pour-over Set',category:'Home',status:'Active',description:'Hand-finished stoneware brewer and cup.',updatedAt:day(4),variants:[{id:'v6',name:'Sand',sku:'POUR-SND',price:6400,stock:12,threshold:5},{id:'v7',name:'Slate',sku:'POUR-SLT',price:6400,stock:0,threshold:5}]},
 {id:'p4',name:'Weekender Duffle',category:'Travel',status:'Active',description:'A considered companion for short trips.',updatedAt:day(5),variants:[{id:'v8',name:'Forest',sku:'DUFF-FOR',price:12800,stock:17,threshold:5}]},
 {id:'p5',name:'Linen Table Runner',category:'Home',status:'Draft',description:'European flax linen, naturally textured.',updatedAt:day(8),variants:[{id:'v9',name:'Oat / 180cm',sku:'RUN-OAT-180',price:5200,stock:14,threshold:5}]},
 {id:'p6',name:'Studio Bottle',category:'Accessories',status:'Active',description:'Insulated stainless steel, 600ml.',updatedAt:day(3),variants:[{id:'v10',name:'Cloud',sku:'BOT-CLD',price:3200,stock:56,threshold:12},{id:'v11',name:'Cobalt',sku:'BOT-COB',price:3200,stock:19,threshold:12}]},
 {id:'p7',name:'Merino Beanie',category:'Apparel',status:'Active',description:'Lightweight merino warmth for cooler days.',updatedAt:day(6),variants:[{id:'v12',name:'Midnight',sku:'BEAN-MID',price:4200,stock:3,threshold:6}]},
 {id:'p8',name:'Pocket Journal Set',category:'Stationery',status:'Archived',description:'Three soft-cover journals with recycled paper.',updatedAt:day(12),variants:[{id:'v13',name:'Set of 3',sku:'JRN-SET3',price:1800,stock:22,threshold:6}]}
];
const customers:Customer[]=[
 {id:'c1',name:'Maya Chen',email:'maya.chen@example.com',phone:'+1 (415) 555-0184',createdAt:day(35)},
 {id:'c2',name:'Oliver Grant',email:'oliver.grant@example.com',phone:'+1 (212) 555-0142',createdAt:day(31)},
 {id:'c3',name:'Priya Kapoor',email:'priya.k@example.com',phone:'+1 (312) 555-0191',createdAt:day(24)},
 {id:'c4',name:'Theo Martin',email:'theo.martin@example.com',phone:'+1 (206) 555-0126',createdAt:day(18)},
 {id:'c5',name:'Sofia Reyes',email:'sofia.reyes@example.com',phone:'+1 (512) 555-0173',createdAt:day(11)},
 {id:'c6',name:'Noah Williams',email:'noah.w@example.com',phone:'+1 (617) 555-0138',createdAt:day(8)}
];
function makeOrder(id:string,customer:Customer,days:number,status:OrderStatus,items:Order['items'],payment:'Paid'|'Unpaid'='Paid'):Order{
 const subtotal=items.reduce((s,i)=>s+i.qty*i.price,0), discount=id==='CO-1045'?800:0, tax=Math.round((subtotal-discount)*.08), shipping=subtotal>7500?0:650;
 return {id,customerId:customer.id,customer:customer.name,email:customer.email,status,payment,currency:'USD',items,subtotal,discount,tax,shipping,total:subtotal-discount+tax+shipping,createdAt:day(days),history:[{status:'Pending',at:day(days)},{status,at:day(Math.max(days-1,0))}]};
}
const orders:Order[]=[
 makeOrder('CO-1048',customers[0],0,'Processing',[{name:'Everyday Canvas Tote',sku:'TOTE-NAT',qty:1,price:2800},{name:'Studio Bottle',sku:'BOT-CLD',qty:1,price:3200}]),
 makeOrder('CO-1047',customers[1],1,'Pending',[{name:'Weekender Duffle',sku:'DUFF-FOR',qty:1,price:12800}], 'Unpaid'),
 makeOrder('CO-1046',customers[2],2,'Shipped',[{name:'Ribbed Cotton Tee',sku:'TEE-M-CHK',qty:2,price:3600}]),
 makeOrder('CO-1045',customers[3],4,'Delivered',[{name:'Ceramic Pour-over Set',sku:'POUR-SND',qty:1,price:6400},{name:'Pocket Journal Set',sku:'JRN-SET3',qty:1,price:1800}]),
 makeOrder('CO-1044',customers[4],6,'Delivered',[{name:'Studio Bottle',sku:'BOT-COB',qty:2,price:3200}]),
 makeOrder('CO-1043',customers[5],9,'Cancelled',[{name:'Merino Beanie',sku:'BEAN-MID',qty:1,price:4200}], 'Unpaid'),
 makeOrder('CO-1042',customers[0],14,'Delivered',[{name:'Everyday Canvas Tote',sku:'TOTE-NAT',qty:2,price:2800}]),
 makeOrder('CO-1041',customers[2],21,'Delivered',[{name:'Ribbed Cotton Tee',sku:'TEE-S-CHK',qty:1,price:3600},{name:'Linen Table Runner',sku:'RUN-OAT-180',qty:1,price:5200}])
];
export const demoData:AppData={products,customers,orders,movements:[{id:'m1',product:'Everyday Canvas Tote',sku:'TOTE-NAT',change:42,reason:'Opening stock',at:day(40)},{id:'m2',product:'Ribbed Cotton Tee',sku:'TEE-L-OLV',change:-2,reason:'Order CO-1046',at:day(2)},{id:'m3',product:'Studio Bottle',sku:'BOT-CLD',change:12,reason:'Restock',at:day(3)}],invoices:[],settings:{name:'Northstar Supply',currency:'USD',timezone:'America/Los_Angeles',email:'hello@northstarsupply.co',address:'1840 Cedar Street, Portland, OR 97205',invoicePrefix:'INV'}};
const KEY='commerceos-demo-v1';
export function loadData():AppData { try { const saved=localStorage.getItem(KEY); if(saved) return JSON.parse(saved) as AppData; } catch {} return structuredClone(demoData); }
export function saveData(data:AppData){localStorage.setItem(KEY,JSON.stringify(data));}
export const money=(amount:number,currency='USD')=>new Intl.NumberFormat(undefined,{style:'currency',currency,maximumFractionDigits:2}).format(amount/100);
export const fmtDate=(date:string)=>new Intl.DateTimeFormat(undefined,{month:'short',day:'numeric',year:'numeric'}).format(new Date(date));
export function calcOrderTotal(subtotal:number,discount:number,tax:number,shipping:number){return subtotal-discount+tax+shipping;}
export function adjustVariant(data:AppData,sku:string,change:number,reason:string):AppData {
 const product=data.products.find(p=>p.variants.some(v=>v.sku===sku)); if(!product) throw new Error('Variant not found.');
 const variant=product.variants.find(v=>v.sku===sku)!; if(variant.stock+change<0) throw new Error('This adjustment would make stock negative.');
 return {...data,products:data.products.map(p=>p.id===product.id?{...p,updatedAt:new Date().toISOString(),variants:p.variants.map(v=>v.sku===sku?{...v,stock:v.stock+change}:v)}:p),movements:[{id:crypto.randomUUID(),product:product.name,sku,change,reason:reason.trim()||'Manual adjustment',at:new Date().toISOString()},...data.movements]};
}
export function moveOrderStatus(data:AppData,orderId:string,status:OrderStatus):AppData {
 const order=data.orders.find(o=>o.id===orderId); if(!order) throw new Error('Order not found.'); if(order.status===status) return data;
 const allowed:Record<OrderStatus,OrderStatus[]>={Pending:['Confirmed','Processing','Cancelled'],Confirmed:['Processing','Cancelled'],Processing:['Shipped','Delivered','Cancelled'],Shipped:['Delivered','Cancelled'],Delivered:[],Cancelled:[]};
 if(!allowed[order.status].includes(status)) throw new Error(`Cannot move an order from ${order.status} to ${status}.`);
 // Reserve on entry to Processing; restore once on cancellation. Terminal states cannot be reopened.
 let next={...data,orders:data.orders.map(o=>o.id===orderId?{...o,status,history:[...o.history,{status,at:new Date().toISOString()}]}:o)};
 if(status==='Processing'){
   for(const item of order.items){const v=next.products.flatMap(p=>p.variants).find(v=>v.sku===item.sku);if(!v)throw new Error(`Inventory SKU ${item.sku} was not found.`);if(v.stock<item.qty)throw new Error(`Insufficient stock for ${item.sku}.`);}
   for(const item of order.items) next=adjustVariant(next,item.sku,-item.qty,`Order ${order.id}`);
 }
 if(status==='Cancelled' && order.history.some(h=>h.status==='Processing')) for(const item of order.items) next=adjustVariant(next,item.sku,item.qty,`Cancellation ${order.id}`);
 return next;
}
export function makeInvoice(data:AppData,order:Order):{data:AppData; invoice:Invoice} {
 const existing=data.invoices.find(i=>i.orderId===order.id); if(existing)return {data,invoice:existing};
 const invoice:Invoice={id:crypto.randomUUID(),orderId:order.id,number:`${data.settings.invoicePrefix}-${String(data.invoices.length+1).padStart(5,'0')}`,status:'Issued',issuedAt:new Date().toISOString(),customer:order.customer,customerEmailSnapshot:order.email,businessNameSnapshot:data.settings.name,businessAddressSnapshot:data.settings.address,businessEmailSnapshot:data.settings.email,items:structuredClone(order.items),subtotal:order.subtotal,discount:order.discount,tax:order.tax,shipping:order.shipping,total:order.total,currency:order.currency};
 return {data:{...data,invoices:[invoice,...data.invoices]},invoice};
}
export function makeBlankCustomer(name:string,email:string,phone:string):Customer {return {id:crypto.randomUUID(),name,email,phone,createdAt:new Date().toISOString()};}
export function monthlySales(data:AppData){const buckets=Array.from({length:7},(_,i)=>{const d=new Date();d.setDate(1);d.setMonth(d.getMonth()-(6-i));return {key:`${d.getFullYear()}-${d.getMonth()}`,label:new Intl.DateTimeFormat(undefined,{month:'short'}).format(d),sales:0,orders:0};}); for(const o of data.orders){if(o.status==='Cancelled'||o.payment!=='Paid')continue;const d=new Date(o.createdAt),b=buckets.find(x=>x.key===`${d.getFullYear()}-${d.getMonth()}`);if(b){b.sales+=o.subtotal-o.discount;b.orders++;}}return buckets;}
