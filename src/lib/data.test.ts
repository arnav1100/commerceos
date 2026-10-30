import {describe,it,expect} from 'vitest';
import {adjustVariant,calcOrderTotal,demoData,makeInvoice,money,moveOrderStatus} from './data';
import type {AppData,Order} from '../types';
const clone=()=>structuredClone(demoData) as AppData;
describe('financial utilities',()=>{
 it('calculates using integer minor units',()=>expect(calcOrderTotal(10000,500,760,650)).toBe(10910));
 it('formats currency from integer minor units',()=>expect(money(12345,'USD')).toMatch(/123\.45/));
 it('does not use floating point totals for invoices',()=>{const o=clone().orders[0];expect(o.total).toBe(o.subtotal-o.discount+o.tax+o.shipping)});
});
describe('inventory',()=>{
 it('records a movement with an atomic demo adjustment',()=>{const data=clone();const before=data.products[0].variants[0].stock;const updated=adjustVariant(data,'TOTE-NAT',4,'Restock');expect(updated.products[0].variants[0].stock).toBe(before+4);expect(updated.movements[0].change).toBe(4);expect(data.products[0].variants[0].stock).toBe(before)});
 it('refuses a change that would create negative stock',()=>expect(()=>adjustVariant(clone(),'POUR-SLT',-1,'Correction')).toThrow(/negative/));
 it('deducts order stock once on Processing and restores once on cancellation',()=>{let data=clone();const stock=data.products[0].variants[0].stock;data=moveOrderStatus(data,'CO-1047','Confirmed');data=moveOrderStatus(data,'CO-1047','Processing');const reserved=data.products.flatMap(p=>p.variants).find(v=>v.sku==='DUFF-FOR')!.stock;expect(reserved).toBe(16);data=moveOrderStatus(data,'CO-1047','Cancelled');expect(data.products.flatMap(p=>p.variants).find(v=>v.sku==='DUFF-FOR')!.stock).toBe(17);expect(data.movements.filter(m=>m.reason.includes('CO-1047'))).toHaveLength(2)});
 it('is idempotent for repeated status updates',()=>{const data=clone();const once=moveOrderStatus(data,'CO-1047','Confirmed');const twice=moveOrderStatus(once,'CO-1047','Confirmed');expect(twice).toEqual(once)});
 it('rejects insufficient stock without partially changing any variant',()=>{const data=clone();const o:Order={...data.orders[0],id:'TEST-LOW',status:'Confirmed',history:[],items:[{name:'Unavailable',sku:'POUR-SLT',qty:1,price:10},{name:'Other',sku:'TOTE-NAT',qty:1,price:10}]};data.orders=[o,...data.orders];const before=structuredClone(data);expect(()=>moveOrderStatus(data,o.id,'Processing')).toThrow(/Insufficient stock/);expect(data.products).toEqual(before.products)});
 it('does not allow reopening a cancelled order',()=>{let d=clone();d=moveOrderStatus(d,'CO-1047','Confirmed');d=moveOrderStatus(d,'CO-1047','Processing');d=moveOrderStatus(d,'CO-1047','Cancelled');expect(()=>moveOrderStatus(d,'CO-1047','Processing')).toThrow(/Cannot move/)});
});
describe('invoice snapshots',()=>{
 it('reuses an issued invoice for the same order and preserves historical pricing',()=>{const data=clone();const order=data.orders[0];const result=makeInvoice(data,order);const changed={...order,subtotal:999999,total:999999};const later={...result.data,orders:result.data.orders.map(o=>o.id===order.id?changed:o)};const again=makeInvoice(later,changed);expect(again.invoice.total).toBe(order.total);expect(again.data.invoices).toHaveLength(1)});
});
