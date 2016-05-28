CREATE OR REPLACE FUNCTION proc_insert_orders(queries INT, random INT) RETURNS void AS $$
DECLARE
   priceList INTEGER[];
   productList INTEGER[];
   idx INT;
   diff INT;
   tables CURSOR FOR SELECT p.id, sum(o.price) as sum FROM orders o, products p WHERE o.product_id = p.id group by p.id order by sum desc limit random * 2 offset 100 - random;
BEGIN
   idx := 0;
   FOR table_record IN tables LOOP
      priceList[idx] := table_record.sum;
      productList[idx] := table_record.id;
      idx := idx + 1;
   END LOOP;

   for a in 0..queries-1 LOOP
      diff := priceList[a % random] - priceList[random + (a % random)] + 1;
      INSERT INTO ORDERS(user_id, product_id, quantity, price, is_cart) VALUES(random() * 100 + 1, productList[random + (a % random)], 1, diff, false);
   END LOOP;
END;
$$ LANGUAGE plpgsql;