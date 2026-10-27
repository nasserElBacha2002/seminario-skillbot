-- Initials de un solo nombre: Luciano → L (antes tomaba las dos primeras letras).
-- Dos palabras siguen siendo la inicial de cada una: Martín Rodríguez → MR.

create or replace function public.profile_initials(p_name text)
returns text
language sql
immutable
as $$
  select case
    when coalesce(words[2], '') <> '' then upper(left(words[1], 1) || left(words[2], 1))
    when coalesce(words[1], '') <> '' then upper(left(words[1], 1))
    else 'SB'
  end
  from (
    select regexp_split_to_array(btrim(coalesce(p_name, '')), '[^[:alnum:]]+') as words
  ) parsed;
$$;
