DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;
CREATE TABLE projet.formations (
	id_formations SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (nom<>''),
	prenom VARCHAR(100) NOT NULL CHECK (prenom<>'')
);
CREATE TABLE projet.blocs (
	id_bloc SERIAL PRIMARY KEY,
	code_bloc VARCHAR(10) NOT NULL CHECK (code_bloc <> ''),
	nb_examens_pas_complet INTEGER NOT NULL CHECK (nb_examens_pas_complet>0),
	id_formation INTEGER REFERENCES projet.formations (id_formations) NOT NULL
);