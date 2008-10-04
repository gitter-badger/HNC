
module Check3 (P (..), check0, res) where

import Data.Map as M hiding (filter)

import Types
import Code hiding (res)
import Top
import Hugs.Observe

data P = P (Map [Char] T, T) | N [Char]
	deriving Show


get_r (P (ur, r)) = r
get_rl l = Prelude.map get_r l

union a b =
	M.unionWith (\a b ->
		case Check3.compare a b of
			(_, True) -> a -- b ?
			(_, False) -> error "union"
	) a b

ch [] [] et u =
	N "too many parameters"
ch (r:[]) [] et u =
--	observe ("u1:"++show u) $
	P (u, set_l r u)
ch r [] et u =
--	observe ("us:"++show u) $
	P (u, set_l (TT r) u)
ch (r:rs) (p1:ps) et u =
	case check p1 et of
		P (rm, r_p1) ->
			case Check3.compare (observe "cmp_1" r) (observe "cmp_2" r_p1) of
				(l2, True) ->
					ch rs ps et
						$ (Check3.union (observe "l2:" l2) $ Check3.union (observe "rm" rm) (observe "u" u))
				(l2, False) ->
					N ("expected "++show (set_l r u)++", actual "++show r_p1)
		N e -> N e

check::C -> Map [Char] T -> P
check (CNum n) et = P (M.empty, T "num")
check (CBool n) et = P (M.empty, T "boolean")
check (CStr n) et = P (M.empty, T "string")
check (CVal n) et =
	case M.lookup n et of
		Just a -> P (M.empty, a)
		Nothing -> N $ (++) "check cannot find " $ show n

check (CL a (K [])) et =
	check a et

check (CL a (K p)) et =
	case check a et of
		P (rm0, TT r) ->
			case ch r p et M.empty of
				P (rm, r) ->
					P (Check3.union rm0 rm, r)
				N e -> N (e++" for "++show a)
--		P (rm, TU n) ->
--			P (putp [n] [TT ((get_rl p_ok)++[TU ('_':n)])] rm, TU ('_':n))
		P (_, TT []) ->
			N ("too many parameters for "++show a)
		P (ur, TU n) ->
			P (putp ["r_"++n] [TT (get_rl p_ok++[TU ('_':n)])] M.empty, TU ('_':n)) -- ?
		N e -> N e
	where
		p_ok = Prelude.map (\x -> check x et) p

check (CL a (S [])) et =
	check a et

check (CL a (S (p:ps))) et =
	case check (CL a (S ps)) (putp [p] [TU p_n] et) of
		P (u, r) ->
			case M.lookup ("r_"++p_n) u of
				Just v -> observe "ok" $
					let w = case (v, r) of
						(a, TT b) -> TT (a:b)
						(a, b) -> TT [a, b]
					in
					P (u, w)
				Nothing -> observe ("no:"++show u) $
					let w = case r of
						TT b -> TT ((TU p_n):b)
						b -> TT [TU p_n, b]
					in
					P (u, w) -- rm ?
		o -> o
	where p_n = ""++p

check (CL a L) et =
	case check a et of
		P (ur, r) ->
			P (ur, TT [TL, r])
		o -> o
	
check (CL a R) et =
	case check a (putp ["_f"] [TU "_f"] et) of
		P (ur, r) -> check a (putp ["_f"] [r] et)
		o -> o

check o et =
	error ("check o: "++show o)

putp (v:vs) (c:cs) et = putp vs cs (M.insert v c et)
putp [] [] et = et
putp o1 o2 et = error ("Check3.putp: "++show o1++", "++show o2)

compare (T a) (T b)|a == b = (M.empty, True)
compare (TD a l1) (TD b l2)|a == b = foldr (\(u1l,r1) (u2l,r2)-> (M.union u1l u2l, r1 && r2)) (M.empty, True) $ zipWith Check3.compare l1 l2
--compare (TT l1) (TT l2) = foldr (\(u1l,u1r,r1) (u2l,u2r,r2) -> (M.union u1l u2l, M.union u1r u2r, r1 && r2)) (M.empty, M.empty, True) $ zipWith Check3.compare l1 l2
-- error: TT [T "num",TU "_l"]/TT [TU "_",TU "z",T "num"]
compare (TT []) (TT []) =
	(M.empty, True)
compare (TT [TU a]) b@(TT l)|1 < length l =
	(M.singleton a b, True)
compare (TT (l1:l1s)) (TT (l2:l2s)) =
	(M.union l ll, b && bb)
	where
		(l, b) = Check3.compare l1 l2
		(ll, bb) = Check3.compare (TT l1s) (TT l2s)
compare (TU a) (TU b) = (M.empty, True)
compare (TU n) b = (M.singleton ("l_"++n) b, True)
compare a (TU n) = (M.singleton ("r_"++n) a, True) -- correct ?
compare TL TL = (M.empty, True) -- return lazy?
--compare t1 t2 = error $ (show t1)++"/"++(show t2)
compare t1 t2 = (M.empty, False)

setu (TD n tt) u = TD n (Prelude.map (\t -> setu t u) tt)
setu (TT tt) u = TT (Prelude.map (\t -> setu t u) tt)
setu (TU n) (t2:t2s) = t2
setu o (t2:t2s) = o
setu o [] = o

settul tt str = Prelude.map (\x -> settu x str) tt
settu (TT tt) str = TT (settul tt str)
settu (TD n tt) str = TD n (settul tt str)
settu (TU n) str = TU (str++n)
settu (T n) str = T n
settu TL str = TL

set_ll tt u = Prelude.map (\x -> set_l x u) tt
set_l (TT tt) u = TT (set_ll tt u)
set_l (TD n tt) u = TD n (set_ll tt u)
set_l (TU n) u =
	case M.lookup ("l_"++n) u of
		Just a -> a
		Nothing -> TU n
set_l (T n) u = T n
set_l TL u = TL

setm (TD n tt) u = TD n (Prelude.map (\t -> setm t u) tt)
setm (TT tt) u = TT (Prelude.map (\t -> setm t u) tt)
setm (TU n) u =
	case M.lookup n u of
		Just a -> a
		Nothing -> TU n
setm o u = o

check0 o =
	check o Top.get_types

res = Check3.compare (TD "list" [TT [T "num",T "num"]]) (TD "list" [TT [T "num",T "num"]])


