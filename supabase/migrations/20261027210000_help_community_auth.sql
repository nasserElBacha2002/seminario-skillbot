-- El centro de ayuda nació con políticas de demo_profile_id().
-- Con Auth, cada cuenta publica y marca solución solo con su auth.uid().

drop policy if exists "demo profile creates topics" on public.help_topics;
drop policy if exists "topic author marks the solution" on public.help_topics;
drop policy if exists "demo profile replies" on public.help_replies;

create policy "own topics can be created" on public.help_topics
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy "topic author marks the solution" on public.help_topics
  for update to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

create policy "own replies can be created" on public.help_replies
  for insert to authenticated
  with check (profile_id = (select auth.uid()));

revoke insert, update on public.help_topics from anon;
revoke insert on public.help_replies from anon;
