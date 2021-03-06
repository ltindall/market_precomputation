create table statetotals(
     stateid int references states(id), 
     statename text, 
     total float

   ); 
   create table producttotals(
        product_id int references products(id), 
        total float, 
        product_name text, 
        category_id int references categories(id)

   ); 
   
  
insert into stateTotals (stateId, total)
select u.state_id , sum(o.price) from orders o, users u 
where o.user_id = u.id 
group by u.state_id; 

insert into productTotals (product_id, total, product_name, category_id)
select o.product_id, sum(o.price), p.name, p.category_id from orders o, products p where o.product_id = p.id
group by o.product_id, p.name, p.category_id; 
