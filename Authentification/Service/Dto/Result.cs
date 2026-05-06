namespace Authentification.Service.Dto
{
    public class Result<T>
    {
        public bool IsSuccess { get; }
        public string? ErrorMessage { get; }
        public T? Value { get; }

        private Result(bool isSuccess, T? value, string? errorMessage)
        {
            IsSuccess = isSuccess;
            Value = value;
            ErrorMessage = errorMessage;
        }

        public static Result<T> Ok(T value)
        {
            return new Result<T>(true, value, null);
        }

        public static Result<T> Fail(string errorMessage)
        {
            return new Result<T>(false, default, errorMessage);
        }
    }
}
