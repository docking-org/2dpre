begin;
	create table weirdmols (like substance);
	-- the crux of the patch- delete molecules that have a space in them
	-- these are weird, and tend to look like this: "CCOCcc |1^1|"
	-- just delete them, saving the ones we delete to an extra table, you know, just in case they're needed for some reason later
	-- where these are present, they tend to be few and far between
	insert into weirdmols (select * from substance where smiles like '% %');
	delete from substance sb using weirdmols w where sb.smiles = w.smiles;
	-- look at all these dependent tables i need to update... need to reduce these things to trigger functions or something
	-- because as of right now the only proper procedure to upload new data is through the upload script
	-- so you can't just "insert into substance" or "delete from substance" and expect things to keep working
	-- of course foreign keys have this function, but this system has reached the point where I'm not using traditional foreign keys anymore (substance_id, catalog_id tables, using partitions as foreign keys)
	-- it would be easier to upload individual molecules if I had access to the function postgres uses to calculate hash partitions, but alas it is locked away in the source code somewhere
	-- the only way to figure out which partition a key belongs to is to insert it into a partitioned table and check which partition it lands in

	-- 
	-- because SOMEHOW this system needs to be fast to insert on as well as fast to select from
	-- I should have totally reworked it, made two systems, one which processes the diff of bulk new data very quickly, and one which is a read-only replica of the diff database (preferably finely partitioned based on chemical properties or the like, for most efficient cache usage)
	-- Moral of the story is I chose a half measure when I should have gone all the way. I'll never make that mistake again. (https://www.youtube.com/watch?v=YSrvFjT0vmY)
	-- that being said, the half-system I've come up with is... serviceable. It can be both inserted to and selected from with reasonable efficiency, especially for large queries.
	-- anyways, rant over. Woe be to any developer from the future peeking under the hood of this jalopy.
	-- delete from substance_id sid using weirdmols w where sid.sub_id = w.sub_id;
	-- create table weirdmols_catsub (like catalog_substance);
	-- insert into weirdmols_catsub(sub_id_fk, cat_content_fk, tranche_id) (select cs.sub_id_fk, cs.cat_content_fk, cs.tranche_id, from catalog_substance cs join weirdmols w on w.sub_id = cs.sub_id_fk);
	-- delete from catalog_substance cs using weirdmols_catsub w where cs.sub_id_fk = w.sub_id_fk;
	-- delete from catalog_substance_cat csc using weirdmols_catsub w where csc.cat_content_fk = w.cat_content_fk and csc.sub_id_fk = w.sub_id_fk;
commit;
