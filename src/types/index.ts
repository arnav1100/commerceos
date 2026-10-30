export type ProductStatus = 'Active' | 'Draft' | 'Archived';
export type OrderStatus = 'Pending' | 'Confirmed' | 'Processing' | 'Shipped' | 'Delivered' | 'Cancelled';
export type PaymentStatus = 'Unpaid' | 'Paid' | 'Partially Refunded' | 'Refunded';
export interface Variant { id:string; name:string; sku:string; price:number; stock:number; threshold:number }
export interface Product { id:string; name:string; category:string; status:ProductStatus; description:string; updatedAt:string; variants:Variant[] }
export interface Customer { id:string; name:string; email:string; phone:string; createdAt:string }
export interface OrderItem { name:string; sku:string; qty:number; price:number }
export interface Order { id:string; customerId:string; customer:string; email:string; status:OrderStatus; payment:PaymentStatus; currency:string; items:OrderItem[]; subtotal:number; discount:number; tax:number; shipping:number; total:number; createdAt:string; history:{status:string; at:string}[] }
export interface Movement { id:string; product:string; sku:string; change:number; reason:string; at:string }
export interface Invoice { id:string; orderId:string; number:string; status:'Issued'; issuedAt:string; customer:string; customerEmailSnapshot?:string; businessNameSnapshot?:string; businessAddressSnapshot?:string; businessEmailSnapshot?:string; items:OrderItem[]; subtotal:number; discount:number; tax:number; shipping:number; total:number; currency:string }
export interface BusinessSettings { name:string; currency:string; timezone:string; email:string; address:string; invoicePrefix:string }
export interface AppData { products:Product[]; customers:Customer[]; orders:Order[]; movements:Movement[]; invoices:Invoice[]; settings:BusinessSettings }
