INSERT INTO Categories VALUES ('Dog', 5);
INSERT INTO Categories VALUES ('Cat', 4.5);
INSERT INTO Categories VALUES ('Kitten', 5.5);
INSERT INTO Categories VALUES ('Puppy', 6);
INSERT INTO Categories VALUES ('Fowl', 3);

/*
-- petowners
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('agabotti0', 'Anastasia', 'Gabotti', '7y8atG', 'agabotti0@moonfruit.com', '1962-08-19', '3542401707331921', '12-253', '638860', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('mcouser1', 'Mindy', 'Couser', '6trz7h6pr', 'mcouser1@icio.us', '1970-05-11', '4905471832535117974', null, '344013', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAHpSURBVDjLhZNbbxJhEIb3T/RWw78g2fjLvLE2ppe1TYNtvGuNRo6BcA4kIBBOgXCU3QXploCAmNQE/VY55PWbj7CWcPBibuab95l3ZmelZrOJRqOBWq2GarWKSqWCcrmMUqmEYrF4BEA6FFK9XsdyudyKfr8vILlc7iBEos4k6PV6orOu6yaEctwF0un0XohElqmYulGiUCiUptMp5vO5yBMwm80ikUjshEjUdV3IxX+45Z5hGPj29RcykbF463a7SKVSiMfjWxCJOq8tLxYLkPj72MCbEw3nz1WkwytIp9MhF4hEIhsQic/IJpOJKJrNZqKz7aWGm7Mu3l/quDppmxBN08gFAoGACZHy+fwzPiMbj1dFSvVBdL49v8PHq/stiKqq5AJer1dABCWTych8RjYajURRu/EDtmMV7y7+QWzHGj4FV++tVotcwO12H5mzJJNJmc/IhsPhFuSDTcfb0w6uTz/zr7MQLkKhEJxO59ONjfL55FgsxgaDgQm5fKHg+lUbtxdt/Jwaj8UWc4THEY1G5XA4zOgSxeLqD7h5/QW/jbkpdjgcFnOJu44jGAzKfr+f0SWuPzGJeX5DvBdA4fP5rHzTjA5MUZSd4oMACo/HY3W5XIzEdrvdsvOU//e78q5WLn6y7/0viZYv/mL7AwwAAAAASUVORK5CYII=');
--caretakers
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('pswoffer2', 'Porty', 'Swoffer', 'tieycEFvNzwp', 'pswoffer2@lycos.com', '1963-05-03', '6304859207771006', null, '831064', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAJrSURBVDjLdVNLaxNRFJ6VP6GgG7eCuBAEN65LFwUXLlyIEsUqKLgQdwXBhaal1YiYNK8mNCXBPBqIMYJJE/IqWeRlkyYpDc2DBJMmpU4TSqNJ+nnPpS06qRc+5s6Zc77vu+fcEQAIUoTD4Tdut7tuMpmOCLSn2Fm5I4GVlZUxq9X6G5JFMYvFcuFMgmPFMlMbMsDlciGfz2M4HGIwGCCbzfIYfaMcyj1xxAkYe+9vtUqlAofDgfX1dQ673c5jEkc9TuB0Oo0MyOVyXJEQi8Xg8XiwvLzMQXuKkZt+v49MJgOqWVxctAhMqb+5uYlkMolUKsUVSV26ThwlEgmEQiEEAgHodLq+wOyJ3W4XOzs72N7eRqlUAjsftra2Th3RPhKJoFAowOfzcaTTaWi1WlGw2WycYH9/H3t7e6hWq9xuPB4/7QGpUhOpMBgMcpBbjUYjUgM5gSiK2N3dRavVQr1e56p0tGg0ygvJMjkjJ0RAAmq1WhTYbH8dHByg0+mg0Wjw4nK5jGKxyEdJyVSodSjwXHUXj97dxD35OOZML6FUKnuC2Wz2EXutVuPHIBLqBTkgAvr28dMsXtnv48uGEt9/eKHwPcFtxRXcmZ6oCWxM59jlmFpaWipSd5vNJtrtNm8mEZB92ewEXNn3cOU/8InMr05BsfoY15+ePzy9kkajccxgMLxms/25trbGSYiMGjg5fRVfN/T/jPVzRkkEoz+HXq+/zOZrZiM6orvh9/tx49lFzHkfQO6V8WL5N9moAylYh8cXFhYCKpUqOvnimvXW/CW89T7kyvSkd0Yw/18CKVjyDEOHbB8/Zyj+B1XaG3VPBqIRAAAAAElFTkSuQmCC');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('lrumbold3', 'Lyda', 'Rumbold', '0Ot4mGppUyT', 'lrumbold3@liveinternet.ru', '1972-04-17', '5219707012117327', null, '959833', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAALbSURBVDjLfZHrM5RhGMb9A33uq7ERq7XsOry7y2qlPqRFDsVk0c4wZZgRckjJeWMQRhkju5HN6V1nERa7atJMw0zMNLUow1SOUby7mNmrdzWJWn245nnumee+7vt3PRYALI6SZy8fnt08kenu0eoW4E666v9+c6gQDQgYB2thJwGPNrfOmBJfK0GTSxT/qfP3/xqcNk3s4SX9rt1VbgZBs+tq9N1zSv98vp5fwzWG3BAUHGkg7CLWPToIw97KJLHBb3QBT+kMXq0zMrQJ0M63IbUoAuIozk2zBjSnyL3FFcImYt2HPAvVlBx97+pRMpoH1n1bRPT6oXmsEk7Fp+BYYA+HPCY9tYPYoDn32WlOo6eSh8bxUuQ+lyK9MwTJnZEQVhJgFdhBWn8Z3v42uv0NaM4dmhP8Bpc6oZJYuqTyh/JNMTJ7wpGo8oPkiRfyO4IxOXId1cOFcMixgyDUuu0QAq/e+RVRywUh54KcqEBGdxgSSF9IakUIb/DD24FIrOpaoO6PBSuDCWaazaZdsnXcoQyIR1xDaFMAigbjEN8sRpjCC0F1F9A3EIdlOofdzWlMtgfDN5sN28QTxpPxDNjEWv0J0O0BZ+uaSoqyoRRIHnsjUOGDqu4ETLRehGG5G4bPJVib6YHioRDiVPvjph5GtOXtfQN+uYuMU8RCdk8KguRiFHelobVBjJX3JAzz2dDe42JnlcSE/IxxvFoUaPYbuTK2hpFkiZqRClSRUnxUp2N7qQ7U9FVoZU7Qz6VgffYZBkuJxddlxLF/DExySGdqOLfsMag4j290cPpPSdj6EPJLOgmNUoo5TTnac9mlZg1MypJxx+a0Jdj+Wrk3fUt3hUbg7J3UbAyoLx3Q5rAWNVn2TLMG9HoL1MoMttfUMCzRGSy1HJAKuz+msDBWj6F0mxazBi8LOSsvZI7UaB6boidRA5lM9GfYYfiOLUU3Ueo0a0qdwqAGk61GfwIga508Gu46TQAAAABJRU5ErkJggg==');
--petowner & caretaker
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('fdecruse5', 'Fredia', 'Decruse', 'fJ4BG9E', 'fdecruse5@google.pl', '1968-12-07', '3545700624440310', null, '372242', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKrSURBVDjLfVNNTFNBEP5aqlItmlcoqG3EP4QQhFitxFNREwwnSbx50aiJBwkQD54gxsTgXQ+K4QoXogduRGPExCAaCCDRQhBCtaX8RKCl7et7u2+d3RZSjHGS6Uz3zTf7zc/aXtw+KvCXCDqx6EeplfMtAW7JMyirfFKHBFy71Yp/CqEFBQlOyixYpILznM/R09etEkRWl6Jed7EGPTaRA0pQDmByWAbpljUYCpzF2FNWKfNzmeDBXOhrb0nwCr6Pz4MT3Q9TCwhU+EAYGHRThgn8iMZQ5vbAMC00XQpgavKLLO2l/W7PfF94dno0PBuC70wD9OS6IpFKbSBJfjIZJz+eO9uEt+ocEmvLGAuNr1CCDnuWsWif+TYJt+aG3eVRwWlTIG1YSBlCqRRGFVeVlGJ6PqQwTwaWf9uEyH58eqO893Rd/XXnfg90XgCd6jVVtwnIs10vcjjAVhcwPDUyROAGiVNT6L5zzLXLYds7Mf6Jcy5szBL2/FHtGCfd6NztGNsalI32wE12tuTQcc3jrdg5RTnzvLlLNobJsBiexmp07vHDV4udksEIAbVS3ykszXwGN9LqJglkOfrmtgJFnnJohythMqujs/lgjUzgqaz1IzT8Fhnq+uSvOP4naxtJuNMMvhNnsRKda1Y92E9LFLjYCJ5Jo54xWiJTLQ43DbIspwb9l1tI32gb92kujBFThxoC1WfEw2B6EsPJ89gULnVbdfojCvU1vGEBbKZ02oMUHt3PMlx5n30zDtVZKtZZWgtOtvBnIS43XlXBo6NuRCIRXKirQzAYRGvLPcTeeVFgt22XZHt288g6jejA1otDcQ2qm9rg9/uhaZoKSiQSGBwcxNDr59AyIYi897u9SPnS1dXVput6C7E4KZmQHyMdME2zvb+/P50f+wdCqc9c4Pf4aQAAAABJRU5ErkJggg==');

*/

--neither
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar) values ('cembleton7', 'Caprice', 'Embleton', 'nf7mnEQ615', 'cembleton7@so-net.ne.jp', '1952-11-22', '5179365826614126', '00-176', '280006', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKoSURBVDjLdZPBTxNREMb5B7h41LuJB+8mJiaGxIheOEhCJMiBaAjRiwdR9KAkBEFiNDYtYFQMEiIBDIQgYGlBS0tLwW1LgUILtBbL0m67bWmXXdh+zisFCsFNfvs2OzPfm/dmpgBAQT5ljSOXCQ0xR4SJGOEhdMx20j8/sJDQEsrorB/zgTjWIjI2krsICtv4MRcAs+V8Co8J5IJHuowe7KkZBONAvy2BPmcC04IMiZxUgtmYD/M9EDkQ0DKDqCD7JMm7c1JEhzkKh6giQ/9oQVzdt+dEtFkB+rhEqH5BQaclguXIvtPwrATdeATebWQz2KRXklaZkckwAZXFZncfo/MNO+N4PxlGmzEMVxBY2QQsy0k6zg6EHYAngfCGHktdZVgZaAD34Ro0rx+OMwHO4Rfx2bRFAjx0EzwG5+Lo+eVlu4QYvSYfhOAAQoZaiM4hSmUDMWcvjC0lu0wg4g6maGcebRTcTiJWX5IF/yXOMZp09dGo+wXkP4MITbxC2tWPvXUTuI/VmUMBnYGHVr8JjT4E2+qRgKWvqFxwPYOaNiHtuw/B9gCLnVVwdlSjpqk7lj0Ctx6D1hDKBn+1i3SRGbC0n79rjkZdT6BKFqS8lZAC5Ugs1GHlUwl+cxzbhDu8RPOqBAcPBNKALwFwdjrzTG0u+A4k/23E55/C03oTFjuHsf3G0h6WUaHS8FSjpRhgNg9hYfQRpf0T0loVdgIVECkTj64Y36a88GwpR2XMb6QwlUs/2g33cB0c398gaC1Faq0cAvcY7rYS9Js8sPmV4410spV7moqAxDqW2m/BUHcWU63FMDZfh9HmxiKvnN7K+cNUf+8iZIsGsvUtrA1X0VtzHtMzdrAB++8w5VN65YzcWHlB1b+8kelqqVDuNnyJ5kZbc9o4/wOexAeGRUz8AAAAAABJRU5ErkJggg==');

-- petowners
CALL add_owner ('agabotti0', 'Anastasia', 'Gabotti', '7y8atG', 'agabotti0@moonfruit.com', '1962-08-19', '3542401707331921', '12-253', '638860', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
CALL add_owner ('mcouser1', 'Mindy', 'Couser', '6trz7h6pr', 'mcouser1@icio.us', '1970-05-11', '4905471832535117974', null, '344013', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAHpSURBVDjLhZNbbxJhEIb3T/RWw78g2fjLvLE2ppe1TYNtvGuNRo6BcA4kIBBOgXCU3QXploCAmNQE/VY55PWbj7CWcPBibuab95l3ZmelZrOJRqOBWq2GarWKSqWCcrmMUqmEYrF4BEA6FFK9XsdyudyKfr8vILlc7iBEos4k6PV6orOu6yaEctwF0un0XohElqmYulGiUCiUptMp5vO5yBMwm80ikUjshEjUdV3IxX+45Z5hGPj29RcykbF463a7SKVSiMfjWxCJOq8tLxYLkPj72MCbEw3nz1WkwytIp9MhF4hEIhsQic/IJpOJKJrNZqKz7aWGm7Mu3l/quDppmxBN08gFAoGACZHy+fwzPiMbj1dFSvVBdL49v8PHq/stiKqq5AJer1dABCWTych8RjYajURRu/EDtmMV7y7+QWzHGj4FV++tVotcwO12H5mzJJNJmc/IhsPhFuSDTcfb0w6uTz/zr7MQLkKhEJxO59ONjfL55FgsxgaDgQm5fKHg+lUbtxdt/Jwaj8UWc4THEY1G5XA4zOgSxeLqD7h5/QW/jbkpdjgcFnOJu44jGAzKfr+f0SWuPzGJeX5DvBdA4fP5rHzTjA5MUZSd4oMACo/HY3W5XIzEdrvdsvOU//e78q5WLn6y7/0viZYv/mL7AwwAAAAASUVORK5CYII=');
CALL add_owner ('fdecruse5', 'Fredia', 'Decruse', 'fJ4BG9E', 'fdecruse5@google.pl', '1968-12-07', '3545700624440310', null, '372242', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKrSURBVDjLfVNNTFNBEP5aqlItmlcoqG3EP4QQhFitxFNREwwnSbx50aiJBwkQD54gxsTgXQ+K4QoXogduRGPExCAaCCDRQhBCtaX8RKCl7et7u2+d3RZSjHGS6Uz3zTf7zc/aXtw+KvCXCDqx6EeplfMtAW7JMyirfFKHBFy71Yp/CqEFBQlOyixYpILznM/R09etEkRWl6Jed7EGPTaRA0pQDmByWAbpljUYCpzF2FNWKfNzmeDBXOhrb0nwCr6Pz4MT3Q9TCwhU+EAYGHRThgn8iMZQ5vbAMC00XQpgavKLLO2l/W7PfF94dno0PBuC70wD9OS6IpFKbSBJfjIZJz+eO9uEt+ocEmvLGAuNr1CCDnuWsWif+TYJt+aG3eVRwWlTIG1YSBlCqRRGFVeVlGJ6PqQwTwaWf9uEyH58eqO893Rd/XXnfg90XgCd6jVVtwnIs10vcjjAVhcwPDUyROAGiVNT6L5zzLXLYds7Mf6Jcy5szBL2/FHtGCfd6NztGNsalI32wE12tuTQcc3jrdg5RTnzvLlLNobJsBiexmp07vHDV4udksEIAbVS3ykszXwGN9LqJglkOfrmtgJFnnJohythMqujs/lgjUzgqaz1IzT8Fhnq+uSvOP4naxtJuNMMvhNnsRKda1Y92E9LFLjYCJ5Jo54xWiJTLQ43DbIspwb9l1tI32gb92kujBFThxoC1WfEw2B6EsPJ89gULnVbdfojCvU1vGEBbKZ02oMUHt3PMlx5n30zDtVZKtZZWgtOtvBnIS43XlXBo6NuRCIRXKirQzAYRGvLPcTeeVFgt22XZHt288g6jejA1otDcQ2qm9rg9/uhaZoKSiQSGBwcxNDr59AyIYi897u9SPnS1dXVput6C7E4KZmQHyMdME2zvb+/P50f+wdCqc9c4Pf4aQAAAABJRU5ErkJggg==');


--caretakers
CALL add_ct ('pswoffer2', 'Porty', 'Swoffer', 'tieycEFvNzwp', 'pswoffer2@lycos.com', '1963-05-03', '6304859207771006', null, '831064', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAJrSURBVDjLdVNLaxNRFJ6VP6GgG7eCuBAEN65LFwUXLlyIEsUqKLgQdwXBhaal1YiYNK8mNCXBPBqIMYJJE/IqWeRlkyYpDc2DBJMmpU4TSqNJ+nnPpS06qRc+5s6Zc77vu+fcEQAIUoTD4Tdut7tuMpmOCLSn2Fm5I4GVlZUxq9X6G5JFMYvFcuFMgmPFMlMbMsDlciGfz2M4HGIwGCCbzfIYfaMcyj1xxAkYe+9vtUqlAofDgfX1dQ673c5jEkc9TuB0Oo0MyOVyXJEQi8Xg8XiwvLzMQXuKkZt+v49MJgOqWVxctAhMqb+5uYlkMolUKsUVSV26ThwlEgmEQiEEAgHodLq+wOyJ3W4XOzs72N7eRqlUAjsftra2Th3RPhKJoFAowOfzcaTTaWi1WlGw2WycYH9/H3t7e6hWq9xuPB4/7QGpUhOpMBgMcpBbjUYjUgM5gSiK2N3dRavVQr1e56p0tGg0ygvJMjkjJ0RAAmq1WhTYbH8dHByg0+mg0Wjw4nK5jGKxyEdJyVSodSjwXHUXj97dxD35OOZML6FUKnuC2Wz2EXutVuPHIBLqBTkgAvr28dMsXtnv48uGEt9/eKHwPcFtxRXcmZ6oCWxM59jlmFpaWipSd5vNJtrtNm8mEZB92ewEXNn3cOU/8InMr05BsfoY15+ePzy9kkajccxgMLxms/25trbGSYiMGjg5fRVfN/T/jPVzRkkEoz+HXq+/zOZrZiM6orvh9/tx49lFzHkfQO6V8WL5N9moAylYh8cXFhYCKpUqOvnimvXW/CW89T7kyvSkd0Yw/18CKVjyDEOHbB8/Zyj+B1XaG3VPBqIRAAAAAElFTkSuQmCC', true);
CALL add_ct ('lrumbold3', 'Lyda', 'Rumbold', '0Ot4mGppUyT', 'lrumbold3@liveinternet.ru', '1972-04-17', '5219707012117327', null, '959833', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAALbSURBVDjLfZHrM5RhGMb9A33uq7ERq7XsOry7y2qlPqRFDsVk0c4wZZgRckjJeWMQRhkju5HN6V1nERa7atJMw0zMNLUow1SOUby7mNmrdzWJWn245nnumee+7vt3PRYALI6SZy8fnt08kenu0eoW4E666v9+c6gQDQgYB2thJwGPNrfOmBJfK0GTSxT/qfP3/xqcNk3s4SX9rt1VbgZBs+tq9N1zSv98vp5fwzWG3BAUHGkg7CLWPToIw97KJLHBb3QBT+kMXq0zMrQJ0M63IbUoAuIozk2zBjSnyL3FFcImYt2HPAvVlBx97+pRMpoH1n1bRPT6oXmsEk7Fp+BYYA+HPCY9tYPYoDn32WlOo6eSh8bxUuQ+lyK9MwTJnZEQVhJgFdhBWn8Z3v42uv0NaM4dmhP8Bpc6oZJYuqTyh/JNMTJ7wpGo8oPkiRfyO4IxOXId1cOFcMixgyDUuu0QAq/e+RVRywUh54KcqEBGdxgSSF9IakUIb/DD24FIrOpaoO6PBSuDCWaazaZdsnXcoQyIR1xDaFMAigbjEN8sRpjCC0F1F9A3EIdlOofdzWlMtgfDN5sN28QTxpPxDNjEWv0J0O0BZ+uaSoqyoRRIHnsjUOGDqu4ETLRehGG5G4bPJVib6YHioRDiVPvjph5GtOXtfQN+uYuMU8RCdk8KguRiFHelobVBjJX3JAzz2dDe42JnlcSE/IxxvFoUaPYbuTK2hpFkiZqRClSRUnxUp2N7qQ7U9FVoZU7Qz6VgffYZBkuJxddlxLF/DExySGdqOLfsMag4j290cPpPSdj6EPJLOgmNUoo5TTnac9mlZg1MypJxx+a0Jdj+Wrk3fUt3hUbg7J3UbAyoLx3Q5rAWNVn2TLMG9HoL1MoMttfUMCzRGSy1HJAKuz+msDBWj6F0mxazBi8LOSsvZI7UaB6boidRA5lM9GfYYfiOLUU3Ueo0a0qdwqAGk61GfwIga508Gu46TQAAAABJRU5ErkJggg==', true);
INSERT INTO Caretakers VALUES ('fdecruse5', true);

-- pets
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('mcouser1', 'Abbey', 'Oth accident on gliding-type pedestrian conveyance, sequela', 'Dog', 'Extra Large', null, null, 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('agabotti0', 'Jacinta', 'Burn of third degree of unspecified knee, initial encounter', 'Puppy', 'Medium', 'Bypass 2 Cor Art from Thor Art w Autol Art, Perc Endo', 'Mv coll w obj-anim rider', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('agabotti0', 'Dawna', 'Unsp injury of superficial vein at shldr/up arm, left arm', 'Dog', 'Extra Small', null, null, 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('mcouser1', 'Barby', 'Other effects of lightning, sequela', 'Cat',  'Large', 'Inspection of Omentum, Percutaneous Endoscopic Approach', 'Light-for-dates <500g', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('fdecruse5', 'Ansell', 'Driver of 3-whl mv injured in clsn w unsp mv in traf, subs', 'Fowl', 'Extra Large', 'Revision of Synthetic Substitute in Lumsac Jt, Open Approach', 'Mal crcnoid sm intst NOS', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('mcouser1', 'Randy', 'Unspecified subluxation of right knee', 'Dog', 'Small', 'Replace L Foot Skin w Autol Sub, Full Thick, Extern', 'Aftercare path fx hip', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('fdecruse5', 'Gail', 'Other reactions to severe stress', 'Fowl',  'Large', 'Removal of Synth Sub from R Knee Jt, Tibial, Perc Approach', 'Bleed esoph var oth dis', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');
insert into ownsPets (username, name, description, cat_name, size, sociability, special_req, img) values ('agabotti0', 'Dana', 'Paresis of accommodation, right eye', 'Cat', 'Small', 'Coord/Dexterity Treatment of Integu Body using Orthosis', 'Mod hypox-ischem enceph', 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAADvSURBVDjLY/z//z8DJYCJgUIwxAwImOWx22uSExvZBvz68cvm5/dfV5HFGEGxUHoiExwVf//8Zfjz+w/D719/GH79/A3UAMK/GH4CMYiWFJJk+PXrN8PN27cunWq/oA/SwwIzyUrYluHvP6AB//7A8e+/f4H4N8Pvf0D8Fyb2h+HLl696WllqJ69Nu2XOArMZpBCuGajoN1jxbwT9FyH36/dvkCt/w10Acvb+h3uxOhvoZzCbi4OLQVJSiuH1q9cMt2/cvXB7zj0beBgQAwwKtS2AFuwH2vwIqFmd5Fi40H/1BFDzQaBrdTFiYYTnBQAI58A33Wys0AAAAABJRU5ErkJggg==');

-- insert availabilities
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-01-08 04:05:06', '2020-02-08 04:05:06', 'pswoffer2');
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-10-08 04:05:06', '2020-12-28 04:05:06', 'pswoffer2');
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-10-08 04:05:06', '2020-12-28 04:05:06', 'lrumbold3');
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-03-08 04:05:06', '2020-05-18 04:05:06', 'pswoffer2');
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-05-02 04:05:06', '2020-06-15 04:05:06', 'lrumbold3');
insert into declares_availabilities (start_timestamp, end_timestamp, caretaker_username) values ('2020-01-08 04:05:06', '2020-01-31 04:05:06', 'fdecruse5');

--timings 
insert into Timings (start_timestamp, end_timestamp ) values ('2020-01-10 04:05:06', '2020-01-31 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-01-11 04:05:06', '2020-01-31 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-11-30 04:05:06', '2020-12-15 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-05-03 04:05:06', '2020-06-05 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-06-01 04:05:06', '2020-06-06 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-01-08 04:05:06', '2020-01-31 04:05:06');
insert into Timings (start_timestamp, end_timestamp ) values ('2020-05-03 04:05:06', '2020-05-05 04:05:06');

-- insert into bids
insert into bids (owner_username, 
      pet_name ,
      bid_start_timestamp ,
      bid_end_timestamp,
      avail_start_timestamp,
      avail_end_timestamp,
      caretaker_username,
      rating,
      review,
      is_successful,
      payment_method,
      mode_of_transfer,
      is_paid,
      total_price ,
      type_of_service )
      values 
      ( 'fdecruse5', 'Ansell',
      '2020-11-30 04:05:06', '2020-12-15 04:05:06',
     '2020-10-08 04:05:06', '2020-12-28 04:05:06' ,
      'pswoffer2', null, null, true, 'smth', 'smth', false, 30, 'smth'
       );

insert into bids (owner_username, 
      pet_name ,
      bid_start_timestamp ,
      bid_end_timestamp,
      avail_start_timestamp,
      avail_end_timestamp,
      caretaker_username,
      rating,
      review,
      is_successful,
      payment_method,
      mode_of_transfer,
      is_paid,
      total_price ,
      type_of_service )
      values 
      ( 'agabotti0', 'Dawna',
        '2020-01-11 04:05:06', '2020-01-31 04:05:06',
      '2020-01-08 04:05:06', '2020-01-31 04:05:06', 
      'fdecruse5', null, null, true, 'smth', 'smth', false, 30, 'smth'
       );


insert into bids (owner_username, 
      pet_name ,
      bid_start_timestamp ,
      bid_end_timestamp,
      avail_start_timestamp,
      avail_end_timestamp,
      caretaker_username,
      rating,
      review,
      is_successful,
      payment_method,
      mode_of_transfer,
      is_paid,
      total_price ,
      type_of_service )
      values 
      ( 'mcouser1', 'Randy', 
      '2020-05-03 04:05:06', '2020-05-05 04:05:06', 
      '2020-05-02 04:05:06', '2020-05-15 04:05:06', 
      'lrumbold3', null, null, true, 'smth', 'smth', false, 30, 'smth'
       );

insert into bids (owner_username, 
      pet_name ,
      bid_start_timestamp ,
      bid_end_timestamp,
      avail_start_timestamp,
      avail_end_timestamp,
      caretaker_username,
      rating,
      review,
      is_successful,
      payment_method,
      mode_of_transfer,
      is_paid,
      total_price ,
      type_of_service )
      values 
      ( 'mcouser1', 'Abbey'
      '2020-01-10 04:05:06', '2020-01-31 04:05:06',
      '2020-01-08 04:05:06', '2020-02-08 04:05:06', 
      'pswoffer2', null, null, true, 'smth', 'smth', false, 30, 'smth'
       );