import GuildIdIndex_Res, {
  loader,
  action,
} from '~/res-routes/guilds/GuildId_Index.mjs'

export default props => {
  return <GuildIdIndex_Res {...props} />
}

export { loader, action }
