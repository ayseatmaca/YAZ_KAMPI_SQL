--
--VERİ TABANI TASARIMI
--
-- Kategori tablosu
CREATE TABLE Kategori (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL
);

-- Satıcı tablosu
CREATE TABLE Satici (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    adres VARCHAR(200)
);

-- Müşteri tablosu
CREATE TABLE Musteri (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    sehir VARCHAR(50),
    kayit_tarihi DATE DEFAULT CURRENT_DATE
);

-- Ürün tablosu
CREATE TABLE Urun (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    fiyat NUMERIC(10,2) NOT NULL,
    stok INT DEFAULT 0,
    kategori_id INT NOT NULL,
    satici_id INT NOT NULL,
    CONSTRAINT fk_kategori FOREIGN KEY (kategori_id) REFERENCES Kategori(id),
    CONSTRAINT fk_satici FOREIGN KEY (satici_id) REFERENCES Satici(id)
);

-- Sipariş tablosu
CREATE TABLE Siparis (
    id SERIAL PRIMARY KEY,
    musteri_id INT NOT NULL,
    tarih DATE DEFAULT CURRENT_DATE,
    toplam_tutar NUMERIC(12,2),
    odeme_turu VARCHAR(50),
    CONSTRAINT fk_musteri FOREIGN KEY (musteri_id) REFERENCES Musteri(id)
);

-- Sipariş Detay tablosu
CREATE TABLE Siparis_Detay (
    id SERIAL PRIMARY KEY,
    siparis_id INT NOT NULL,
    urun_id INT NOT NULL,
    adet INT NOT NULL,
    fiyat NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_siparis FOREIGN KEY (siparis_id) REFERENCES Siparis(id),
    CONSTRAINT fk_urun FOREIGN KEY (urun_id) REFERENCES Urun(id)
);
--
--VERİ EKLEME VE GÜNCELLEME
--
-- Kategoriler
-- Kategoriler
INSERT INTO Kategori (id, ad) VALUES
(1, 'Elektronik'),
(2, 'Giyim'),
(3, 'Kitap'),
(4, 'Ev & Yaşam'),
(5, 'Spor');

INSERT INTO Kategori (ad) VALUES
('Elektronik'), ('Giyim'), ('Kitap'), ('Ev & Yaşam'), ('Spor');


-- Satıcılar
INSERT INTO Satici (id, ad, adres) VALUES
(1, 'TechStore', 'İstanbul, Türkiye'),
(2, 'FashionShop', 'Ankara, Türkiye'),
(3, 'BookWorld', 'İzmir, Türkiye'),
(4, 'HomeLife', 'Bursa, Türkiye'),
(5, 'Sportify', 'Antalya, Türkiye');
INSERT INTO Satici (ad, adres) VALUES
('TechStore', 'İstanbul, Türkiye'),
('FashionShop', 'Ankara, Türkiye'),
('BookWorld', 'İzmir, Türkiye'),
('HomeLife', 'Bursa, Türkiye'),
('Sportify', 'Antalya, Türkiye');

--Müsşteri Ekleme
--

DO $$
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO Musteri (ad, soyad, email, sehir)
        VALUES (
            'Ad' || i,
            'Soyad' || i,
            'musteri' || i || '@example.com',
            CASE WHEN i % 5 = 1 THEN 'İstanbul'
                 WHEN i % 5 = 2 THEN 'Ankara'
                 WHEN i % 5 = 3 THEN 'İzmir'
                 WHEN i % 5 = 4 THEN 'Bursa'
                 ELSE 'Antalya' END
        );
    END LOOP;
END $$;

--Ürün Ekleme
DO $$
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO Urun (ad, fiyat, stok, kategori_id, satici_id)
        VALUES (
            'Urun' || i,
            (10 + random() * 990)::NUMERIC(10,2),
            (5 + floor(random()*95))::INT,
            1 + (i % 5),  -- kategori_id 1-5 arası
            1 + (i % 5)   -- satici_id 1-5 arası
        );
    END LOOP;
END $$;
--
TRUNCATE TABLE Urun RESTART IDENTITY CASCADE;
--Müşteri ıd sıfırdan başlatıyor
ALTER SEQUENCE musterı_id_seq RESTART WITH 1;
--
--ÜRÜN DETAYI EKLEME
DO $$
DECLARE
    siparis_id INT;
    urun_id INT;
    adet INT;
    urun_fiyat NUMERIC(10,2);  -- Değişken adını fiyat yerine urun_fiyat yaptık
BEGIN
    FOR i IN 1..100 LOOP
        -- Sipariş ekleme
        INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu)
        VALUES (
            1 + (i % 100), -- rastgele müşteri
            0,              -- toplam tutar geçici 0
            CASE WHEN i % 2 = 0 THEN 'Kredi Kartı' ELSE 'Havale' END
        ) RETURNING id INTO siparis_id;
        
        -- Sipariş detay ekleme (1-5 ürün)
        FOR j IN 1..(1 + (random()*4)::INT) LOOP
            urun_id := 1 + (random()*99)::INT;
            SELECT fiyat INTO urun_fiyat FROM Urun WHERE id = urun_id;
            adet := 1 + (random()*5)::INT;
            
            INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat)
            VALUES (siparis_id, urun_id, adet, urun_fiyat);
            
            -- Toplam tutarı güncelle
            UPDATE Siparis
            SET toplam_tutar = toplam_tutar + (urun_fiyat * adet)
            WHERE id = siparis_id;
            
            -- Stok güncelle
            UPDATE Urun
            SET stok = GREATEST(stok - adet, 0)
            WHERE id = urun_id;
        END LOOP;
    END LOOP;
END $$;

--
--. VERİ SORGULAMA VE RAPORLAMA
--
--temel sorgular
--🔹 En çok sipariş veren 5 müşteri
select m.id as musteri_id, m.ad || ' ' || m.soyad as musteri_adi,
count(s.id) as siparis_sayisi
FROM musteri m
join siparis s on m.id = s.musteri_id
group by m.id, m.ad , m.soyad
order by siparis_sayisi desc
LIMIT 5;
--COUNT(s.id) → müşteri başına sipariş sayısını verir.
--LIMIT 5 → sadece en çok sipariş veren 5 müşteri listelenir.
--m.ad || ' ' || m.soyad → ad ve soyadı birleştirir.


--🔹 2. En Çok Satılan Ürünler
select u.id as urun_adi, u.id as urun_adi,
sum(sd.adet) as toplam_satis_adeti
from siparis_detay sd
join urun u on sd.urun_id = u.id
group by u.id,u.ad
order by toplam_satis_adeti desc;
--SUM(sd.adet) → toplam satış miktarı.
--En çok satılan ürünler büyükten küçüğe sıralanır.

--🔹 3. En Yüksek Cirosu Olan Satıcılar
select s.id as satici_id, s.ad as satici_adi,
sum(sd.adet*sa.fiyat) as toplam_ciro
from satici s
join urun u on s.id = u.satici_id
join siparis_detay sd on u.id _ sd.urun_id
group by s.id , s.ad
order by toplam_ciro desc;
--adet * fiyat → her sipariş satırının geliri.
--SUM(...) → satıcının toplam cirosu.
--ORDER BY toplam_ciro DESC → en yüksek cirodan düşüğe doğru sıralar.


--AGGREGATE & GROUP BY SORGULARI
--🔹 1. Şehirlere Göre Müşteri Sayısı
select sehir,count(id) as musteri_sayisi
from musteri
group by sehir
order by musteri_sayisi desc;
--COUNT(id) → her şehirdeki müşteri sayısını sayar.
--ORDER BY → en çok müşterisi olan şehirden en az olana sıralar.

--🔹 2. Kategori Bazlı Toplam Satışlar
select k.ad as kategori_adi,
sum(sd.adet*sd.fiyat) as toplam_satis
from siparis_detay sd
join urun u on sd.urun_id = u.id
join kategori k on u.kategori_id = k.id
group by k.ad
order by toplam_satis desc;
--adet * fiyat → her satırdaki ürün satış tutarı.
--SUM(...) → kategoriye göre toplam satış tutarı.
--ORDER BY → en çok satış yapan kategoriyi en üstte gösterir.

--🔹 3. Aylara Göre Sipariş Sayısı
select to_char(tarih,'YYYY-MM') as ay,
count(id) as siparis_sayisi
from siparis
group by ay
order by ay;
--TO_CHAR(tarih, 'YYYY-MM') → sipariş tarihini yıl–ay formatına dönüştürür.
--COUNT(id) → o ayda verilen sipariş sayısını sayar.
--ORDER BY ay → kronolojik sıralama.

--JOIN SORGULARI
--🔹 1. Siparişlerde Müşteri Bilgisi + Ürün Bilgisi + Satıcı Bilgisi
select 
s.id as siparis_id,
m.ad||' '|| m.soyad as musteri_adi,
u.ad as urun_adi,
sa.ad as satici_adi,
sd.adet,sd.fiyat,
(sd.adet*sd.fiyat) as toplam_tutar,
s.tarih as siparis_tarihi
from siparis s
join musteri m on s.musteri_id = m.id
join siparis_detay sd on s.id = sd.siparis_id
join urun u on sd.urun_id = u.id
join satici sa on u.satici_id = sa.id
order by s.id
--JOIN işlemleri tüm bağlantıları kurar (müşteri–sipariş–ürün–satıcı).
--(adet * fiyat) → satır bazında toplam ürün tutarı.
--Sonuç: siparişin kimden, neyi, hangi satıcıdan, kaç adet aldığı görünür.

--🔹 2. Hiç Satılmamış Ürünler
select u.id as urun_id,
u.ad as urun_adi,
u.fiyat,
u.stok
from urun u
left join siparis_detay sd on u.id = sd.urun_id
where sd.urun_id is null;
--LEFT JOIN → tüm ürünleri getirir, ancak eşleşen sipariş detayı olmayanları da gösterir.
--WHERE sd.urun_id IS NULL → satılmamış (hiç sipariş almamış) ürünleri filtreler.

--🔹 3. Hiç Sipariş Vermemiş Müşteriler
select m.id as musteri_id,
m.ad || ' ' || m.soyad AS musteri_adi,
m.email,
m.sehir
from musteri m
left join siparis s on m.id = s.musteri_id
where s.id is null;
--LEFT JOIN → tüm müşterileri getirir, ancak sipariş tablosunda olmayanları da korur.
--WHERE s.id IS NULL → hiç sipariş vermemişleri seçer.






