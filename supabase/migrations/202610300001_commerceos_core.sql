-- COMMERCEOS production schema (PostgreSQL / Supabase)
-- Apply only after reviewing for your deployment and regional tax requirements.
create extension if not exists pgcrypto;
create type public.member_role as enum ('owner','admin','staff','viewer');
create type public.product_status as enum ('active','draft','archived');
create type public.order_status as enum ('pending','confirmed','processing','shipped','delivered','cancelled');
create type public.payment_status as enum ('unpaid','paid','partially_refunded','refunded');
create type public.invoice_status as enum ('issued','void');
create type public.movement_type as enum ('adjustment','order_reserve','order_release','opening_stock','return');

create table public.businesses (
 id uuid primary key default gen_random_uuid(), name text not null check (length(trim(name)) between 1 and 160),
 currency char(3) not null default 'USD' check(currency ~ '^[A-Z]{3}$'), timezone text not null default 'UTC',
 created_at timestamptz not null default now()
);
create table public.business_members (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, role public.member_role not null default 'owner', created_at timestamptz not null default now(),
 unique(business_id,user_id)
);
create index business_members_user_idx on public.business_members(user_id,business_id);
create table public.business_settings (
 id uuid primary key default gen_random_uuid(), business_id uuid not null unique references public.businesses(id) on delete cascade,
 business_name text not null, business_address text not null default '', business_email text not null default '', invoice_prefix text not null default 'INV' check(length(invoice_prefix) between 1 and 8),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.categories (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 120), created_at timestamptz not null default now(), unique(business_id,name), unique(business_id,id)
);
create table public.products (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 240), slug text not null, description text not null default '', status public.product_status not null default 'draft',
 category_id uuid, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(business_id,slug), unique(business_id,id), foreign key(business_id,category_id) references public.categories(business_id,id) on delete restrict
);
create index products_business_status_idx on public.products(business_id,status,created_at desc);
create table public.product_variants (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 product_id uuid not null, sku text not null check(length(trim(sku)) between 1 and 80), sku_normalized text generated always as (upper(trim(sku))) stored,
 name text not null default 'Default', price_amount bigint not null check(price_amount > 0), currency char(3) not null check(currency ~ '^[A-Z]{3}$'),
 stock_quantity integer not null default 0 check(stock_quantity>=0), low_stock_threshold integer not null default 0 check(low_stock_threshold>=0), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(business_id,sku_normalized), unique(product_id,id), foreign key(business_id,product_id) references public.products(business_id,id) on delete cascade
);
create index variants_product_idx on public.product_variants(product_id);
create table public.product_images (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 storage_path text not null unique, sort_order integer not null default 0, created_at timestamptz not null default now()
);
create index product_images_product_idx on public.product_images(product_id,sort_order);
create table public.customers (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 180), email text, phone text, created_at timestamptz not null default now(),
 unique(business_id,id)
);
create index customers_business_name_idx on public.customers(business_id,name);
create index customers_business_email_idx on public.customers(business_id,email);
create table public.orders (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade, customer_id uuid references public.customers(id) on delete set null,
 order_number text not null, status public.order_status not null default 'pending', payment_status public.payment_status not null default 'unpaid',
 currency char(3) not null check(currency ~ '^[A-Z]{3}$'), subtotal_amount bigint not null default 0 check(subtotal_amount>=0), discount_amount bigint not null default 0 check(discount_amount>=0), tax_amount bigint not null default 0 check(tax_amount>=0), shipping_amount bigint not null default 0 check(shipping_amount>=0), total_amount bigint not null check(total_amount>=0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(business_id,order_number), unique(business_id,id),
 check(total_amount=subtotal_amount-discount_amount+tax_amount+shipping_amount)
);
create index orders_business_created_idx on public.orders(business_id,created_at desc);
create index orders_business_status_idx on public.orders(business_id,status,payment_status,created_at desc);
create table public.order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_variant_id uuid references public.product_variants(id) on delete set null,
 product_name_snapshot text not null, sku_snapshot text not null, quantity integer not null check(quantity>0), unit_price_snapshot bigint not null check(unit_price_snapshot>=0), line_total_amount bigint not null check(line_total_amount=quantity*unit_price_snapshot), created_at timestamptz not null default now()
);
create index order_items_order_idx on public.order_items(order_id);
create table public.order_status_events (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, status public.order_status not null, note text not null default '', created_at timestamptz not null default now(), actor_id uuid references auth.users(id) on delete set null
);
create index order_events_order_idx on public.order_status_events(order_id,created_at);
create table public.inventory_movements (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 product_variant_id uuid not null references public.product_variants(id) on delete restrict, movement_type public.movement_type not null,
 quantity_change integer not null check(quantity_change<>0), reason text not null check(length(trim(reason)) between 1 and 240), order_id uuid references public.orders(id) on delete set null, created_at timestamptz not null default now(), actor_id uuid references auth.users(id) on delete set null
);
create index movements_business_date_idx on public.inventory_movements(business_id,created_at desc);
create index movements_variant_date_idx on public.inventory_movements(product_variant_id,created_at desc);
create table public.order_stock_effects (
 order_id uuid primary key references public.orders(id) on delete cascade, business_id uuid not null references public.businesses(id) on delete cascade,
 active boolean not null default true, reserved_at timestamptz not null default now(), released_at timestamptz
);
create table public.invoices (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade, order_id uuid not null references public.orders(id) on delete restrict,
 invoice_number text not null, status public.invoice_status not null default 'issued', currency char(3) not null check(currency ~ '^[A-Z]{3}$'), subtotal_amount bigint not null, discount_amount bigint not null, tax_amount bigint not null, shipping_amount bigint not null, total_amount bigint not null,
 business_name_snapshot text not null, business_address_snapshot text not null default '', business_email_snapshot text not null default '', customer_name_snapshot text not null, customer_email_snapshot text not null default '', issued_at timestamptz not null default now(), due_at timestamptz, created_at timestamptz not null default now(), unique(business_id,invoice_number), unique(business_id,order_id), unique(business_id,id)
);
create index invoices_business_issued_idx on public.invoices(business_id,issued_at desc);
create table public.invoice_items (
 id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices(id) on delete cascade,
 product_name_snapshot text not null, sku_snapshot text not null, quantity integer not null check(quantity>0), unit_price_amount bigint not null check(unit_price_amount>=0), line_total_amount bigint not null check(line_total_amount=quantity*unit_price_amount)
);

-- Membership helper is SECURITY DEFINER to avoid recursive RLS evaluation on business_members.
create or replace function public.is_business_member(target_business uuid) returns boolean language sql stable security definer set search_path=public,auth as $$
 select exists(select 1 from public.business_members m where m.business_id=target_business and m.user_id=auth.uid())
$$;
create or replace function public.has_business_role(target_business uuid, allowed public.member_role[]) returns boolean language sql stable security definer set search_path=public,auth as $$
 select exists(select 1 from public.business_members m where m.business_id=target_business and m.user_id=auth.uid() and m.role=any(allowed))
$$;
revoke all on function public.is_business_member(uuid) from public;
revoke all on function public.has_business_role(uuid,public.member_role[]) from public;
grant execute on function public.is_business_member(uuid) to authenticated;
grant execute on function public.has_business_role(uuid,public.member_role[]) to authenticated;

-- Use after signup/login to create the business and owner membership atomically.
create or replace function public.create_business(p_name text,p_currency char(3) default 'USD',p_timezone text default 'UTC') returns uuid
language plpgsql security definer set search_path=public,auth as $$
declare new_id uuid; begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if length(trim(p_name)) not between 1 and 160 or p_currency !~ '^[A-Z]{3}$' then raise exception 'Invalid workspace details' using errcode='22023'; end if;
 insert into public.businesses(name,currency,timezone) values(trim(p_name),p_currency,coalesce(nullif(trim(p_timezone),''),'UTC')) returning id into new_id;
 insert into public.business_members(business_id,user_id,role) values(new_id,auth.uid(),'owner');
 insert into public.business_settings(business_id,business_name) values(new_id,trim(p_name));
 return new_id;
end $$;
revoke all on function public.create_business(text,char,text) from public;
grant execute on function public.create_business(text,char,text) to authenticated;

-- Atomic, membership-checked stock adjustment; all inventory writes go through this function.
create or replace function public.adjust_inventory(p_variant_id uuid,p_change integer,p_reason text) returns integer
language plpgsql security definer set search_path=public,auth as $$
declare v public.product_variants%rowtype; b uuid; new_stock integer; begin
 if auth.uid() is null or p_change=0 or length(trim(p_reason)) not between 1 and 240 then raise exception 'Invalid adjustment' using errcode='22023'; end if;
 select pv.* into v from public.product_variants pv join public.products p on p.id=pv.product_id where pv.id=p_variant_id for update of pv;
 if not found then raise exception 'Variant not found' using errcode='P0002'; end if;
 select p.business_id into b from public.products p where p.id=v.product_id;
 if not public.has_business_role(b,array['owner','admin','staff']::public.member_role[]) then raise exception 'Not authorized' using errcode='42501'; end if;
 new_stock:=v.stock_quantity+p_change; if new_stock<0 then raise exception 'Insufficient stock' using errcode='23514'; end if;
 update public.product_variants set stock_quantity=new_stock,updated_at=now() where id=v.id;
 insert into public.inventory_movements(business_id,product_variant_id,movement_type,quantity_change,reason,actor_id) values(b,v.id,'adjustment',p_change,trim(p_reason),auth.uid());
 return new_stock;
end $$;
revoke all on function public.adjust_inventory(uuid,integer,text) from public;
grant execute on function public.adjust_inventory(uuid,integer,text) to authenticated;

-- Idempotent lifecycle: first transition into processing reserves stock once; cancellation releases once.
create or replace function public.set_order_status(p_order_id uuid,p_status public.order_status,p_note text default '') returns public.orders
language plpgsql security definer set search_path=public,auth as $$
declare o public.orders%rowtype; line record; pv public.product_variants%rowtype; eff public.order_stock_effects%rowtype; begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into o from public.orders where id=p_order_id for update;
 if not found then raise exception 'Order not found' using errcode='P0002'; end if;
 if not public.has_business_role(o.business_id,array['owner','admin','staff']::public.member_role[]) then raise exception 'Not authorized' using errcode='42501'; end if;
 if o.status=p_status then return o; end if;
 if not ((o.status='pending' and p_status in ('confirmed','processing','cancelled')) or (o.status='confirmed' and p_status in ('processing','cancelled')) or (o.status='processing' and p_status in ('shipped','delivered','cancelled')) or (o.status='shipped' and p_status in ('delivered','cancelled'))) then raise exception 'Invalid order status transition' using errcode='22023'; end if;
 if p_status='processing' and o.status<>'processing' then
   select * into eff from public.order_stock_effects where order_id=o.id for update;
   if not found or not eff.active then
     for line in select product_variant_id,sum(quantity)::integer as quantity,min(sku_snapshot) as sku_snapshot from public.order_items where order_id=o.id and product_variant_id is not null group by product_variant_id order by product_variant_id loop
       select * into pv from public.product_variants where id=line.product_variant_id for update;
       if not found or pv.stock_quantity<line.quantity then raise exception 'Insufficient stock for SKU %',line.sku_snapshot using errcode='23514'; end if;
     end loop;
     for line in select product_variant_id,sum(quantity)::integer as quantity,min(sku_snapshot) as sku_snapshot from public.order_items where order_id=o.id and product_variant_id is not null group by product_variant_id order by product_variant_id loop
       update public.product_variants set stock_quantity=stock_quantity-line.quantity,updated_at=now() where id=line.product_variant_id;
       insert into public.inventory_movements(business_id,product_variant_id,movement_type,quantity_change,reason,order_id,actor_id) values(o.business_id,line.product_variant_id,'order_reserve',-line.quantity,'Order '||o.order_number,o.id,auth.uid());
     end loop;
     insert into public.order_stock_effects(order_id,business_id,active) values(o.id,o.business_id,true) on conflict(order_id) do update set active=true,reserved_at=now(),released_at=null;
   end if;
 end if;
 if p_status='cancelled' then
   select * into eff from public.order_stock_effects where order_id=o.id for update;
   if found and eff.active then
     for line in select product_variant_id,sum(quantity)::integer as quantity from public.order_items where order_id=o.id and product_variant_id is not null group by product_variant_id order by product_variant_id loop
       update public.product_variants set stock_quantity=stock_quantity+line.quantity,updated_at=now() where id=line.product_variant_id;
       insert into public.inventory_movements(business_id,product_variant_id,movement_type,quantity_change,reason,order_id,actor_id) values(o.business_id,line.product_variant_id,'order_release',line.quantity,'Cancellation '||o.order_number,o.id,auth.uid());
     end loop;
     update public.order_stock_effects set active=false,released_at=now() where order_id=o.id;
   end if;
 end if;
 update public.orders set status=p_status,updated_at=now() where id=o.id returning * into o;
 insert into public.order_status_events(order_id,status,note,actor_id) values(o.id,p_status,coalesce(p_note,''),auth.uid());
 return o;
end $$;
revoke all on function public.set_order_status(uuid,public.order_status,text) from public;
grant execute on function public.set_order_status(uuid,public.order_status,text) to authenticated;

-- Keep foreign keys tenant-consistent even when a caller knows another tenant's UUID.
create or replace function public.validate_order_tenant_links() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.customer_id is not null and not exists(select 1 from public.customers c where c.id=new.customer_id and c.business_id=new.business_id) then raise exception 'Customer is outside this business' using errcode='23503'; end if;
 return new;
end $$;
create trigger orders_tenant_links before insert or update of business_id,customer_id on public.orders for each row execute function public.validate_order_tenant_links();
create or replace function public.validate_order_item_tenant_link() returns trigger language plpgsql security definer set search_path=public as $$
declare ob uuid; vb uuid; begin
 select business_id into ob from public.orders where id=new.order_id;
 if new.product_variant_id is not null then select p.business_id into vb from public.product_variants v join public.products p on p.id=v.product_id where v.id=new.product_variant_id; if vb is distinct from ob then raise exception 'Variant is outside this order business' using errcode='23503'; end if; end if;
 return new;
end $$;
create trigger order_item_tenant_links before insert or update of order_id,product_variant_id on public.order_items for each row execute function public.validate_order_item_tenant_link();
create or replace function public.validate_invoice_tenant_link() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if not exists(select 1 from public.orders o where o.id=new.order_id and o.business_id=new.business_id) then raise exception 'Order is outside this business' using errcode='23503'; end if;
 return new;
end $$;
create trigger invoice_tenant_link before insert or update of order_id,business_id on public.invoices for each row execute function public.validate_invoice_tenant_link();

-- Issue an immutable invoice snapshot from a verified order. Business row lock serializes number generation per tenant.
create or replace function public.issue_invoice(p_order_id uuid) returns uuid language plpgsql security definer set search_path=public,auth as $$
declare o public.orders%rowtype; s public.business_settings%rowtype; bname text; customer_name text; customer_email text; prefix text; next_no bigint; new_invoice uuid; line record; begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into o from public.orders where id=p_order_id for update;
 if not found then raise exception 'Order not found' using errcode='P0002'; end if;
 if not public.has_business_role(o.business_id,array['owner','admin','staff']::public.member_role[]) then raise exception 'Not authorized' using errcode='42501'; end if;
 select * into s from public.business_settings where business_id=o.business_id;
 select name,email into customer_name,customer_email from public.customers where id=o.customer_id;
 select coalesce(s.invoice_prefix,'INV') into prefix;
 perform 1 from public.businesses where id=o.business_id for update;
 if exists(select 1 from public.invoices where business_id=o.business_id and order_id=o.id) then select id into new_invoice from public.invoices where business_id=o.business_id and order_id=o.id; return new_invoice; end if;
 select count(*)+1 into next_no from public.invoices where business_id=o.business_id;
 insert into public.invoices(business_id,order_id,invoice_number,status,currency,subtotal_amount,discount_amount,tax_amount,shipping_amount,total_amount,business_name_snapshot,business_address_snapshot,business_email_snapshot,customer_name_snapshot,customer_email_snapshot)
 values(o.business_id,o.id,prefix||'-'||lpad(next_no::text,5,'0'),'issued',o.currency,o.subtotal_amount,o.discount_amount,o.tax_amount,o.shipping_amount,o.total_amount,coalesce(s.business_name,(select name from public.businesses where id=o.business_id)),coalesce(s.business_address,''),coalesce(s.business_email,''),coalesce(customer_name,'Customer'),coalesce(customer_email,'')) returning id into new_invoice;
 for line in select product_name_snapshot,sku_snapshot,quantity,unit_price_snapshot,line_total_amount from public.order_items where order_id=o.id loop
   insert into public.invoice_items(invoice_id,product_name_snapshot,sku_snapshot,quantity,unit_price_amount,line_total_amount) values(new_invoice,line.product_name_snapshot,line.sku_snapshot,line.quantity,line.unit_price_snapshot,line.line_total_amount);
 end loop;
 return new_invoice;
end $$;
revoke all on function public.issue_invoice(uuid) from public;
grant execute on function public.issue_invoice(uuid) to authenticated;

-- RLS enablement.
do $$ declare t text; begin foreach t in array array['businesses','business_members','business_settings','categories','products','product_variants','product_images','customers','orders','order_items','order_status_events','inventory_movements','order_stock_effects','invoices','invoice_items'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy business_member_read on public.businesses for select to authenticated using(public.is_business_member(id));
create policy business_owner_update on public.businesses for update to authenticated using(public.has_business_role(id,array['owner','admin']::public.member_role[])) with check(public.has_business_role(id,array['owner','admin']::public.member_role[]));
create policy members_read_same_business on public.business_members for select to authenticated using(public.is_business_member(business_id));
-- Membership writes are intentionally not exposed through table policies; use a vetted invite RPC.
create policy settings_member_read on public.business_settings for select to authenticated using(public.is_business_member(business_id));
create policy settings_admin_write on public.business_settings for all to authenticated using(public.has_business_role(business_id,array['owner','admin']::public.member_role[])) with check(public.has_business_role(business_id,array['owner','admin']::public.member_role[]));
create policy categories_member_read on public.categories for select to authenticated using(public.is_business_member(business_id));
create policy categories_staff_write on public.categories for all to authenticated using(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[])) with check(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[]));
create policy products_member_read on public.products for select to authenticated using(public.is_business_member(business_id));
create policy products_staff_write on public.products for all to authenticated using(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[])) with check(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[]));
create policy customers_member_read on public.customers for select to authenticated using(public.is_business_member(business_id));
create policy customers_staff_write on public.customers for all to authenticated using(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[])) with check(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[]));
create policy orders_member_read on public.orders for select to authenticated using(public.is_business_member(business_id));
create policy orders_staff_write on public.orders for insert to authenticated with check(public.has_business_role(business_id,array['owner','admin','staff']::public.member_role[]));
create policy order_items_member_read on public.order_items for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and public.is_business_member(o.business_id)));
create policy order_items_staff_write on public.order_items for all to authenticated using(exists(select 1 from public.orders o where o.id=order_id and public.has_business_role(o.business_id,array['owner','admin','staff']::public.member_role[]))) with check(exists(select 1 from public.orders o where o.id=order_id and public.has_business_role(o.business_id,array['owner','admin','staff']::public.member_role[])));
create policy events_member_read on public.order_status_events for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and public.is_business_member(o.business_id)));
create policy variant_member_read on public.product_variants for select to authenticated using(exists(select 1 from public.products p where p.id=product_id and public.is_business_member(p.business_id)));
create policy variant_staff_write on public.product_variants for all to authenticated using(exists(select 1 from public.products p where p.id=product_id and public.has_business_role(p.business_id,array['owner','admin','staff']::public.member_role[]))) with check(exists(select 1 from public.products p where p.id=product_id and public.has_business_role(p.business_id,array['owner','admin','staff']::public.member_role[])));
create policy product_images_member_read on public.product_images for select to authenticated using(exists(select 1 from public.products p where p.id=product_id and public.is_business_member(p.business_id)));
create policy product_images_staff_write on public.product_images for all to authenticated using(exists(select 1 from public.products p where p.id=product_id and public.has_business_role(p.business_id,array['owner','admin','staff']::public.member_role[]))) with check(exists(select 1 from public.products p where p.id=product_id and public.has_business_role(p.business_id,array['owner','admin','staff']::public.member_role[])));
create policy movements_member_read on public.inventory_movements for select to authenticated using(public.is_business_member(business_id));
create policy stock_effect_member_read on public.order_stock_effects for select to authenticated using(public.is_business_member(business_id));
create policy invoice_member_read on public.invoices for select to authenticated using(public.is_business_member(business_id));
-- Invoice creation is exposed only through the issue_invoice() snapshot RPC.
create policy invoice_items_member_read on public.invoice_items for select to authenticated using(exists(select 1 from public.invoices i where i.id=invoice_id and public.is_business_member(i.business_id)));
-- Invoice item creation happens atomically inside issue_invoice().

-- Storage convention: private bucket product-images, object path starts with business UUID.
-- Create bucket in Supabase Storage dashboard (private, max file size 5MB, image MIME allowlist), then apply:
-- create policy product_images_read on storage.objects for select to authenticated using(bucket_id='product-images' and public.is_business_member((storage.foldername(name))[1]::uuid));
-- create policy product_images_insert on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.has_business_role((storage.foldername(name))[1]::uuid,array['owner','admin','staff']::public.member_role[]));
-- Never expose service_role keys in browser code.
